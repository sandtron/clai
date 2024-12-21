#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'logger'
require 'time'
require 'yaml'
require 'securerandom'
require 'fileutils'

def read_files_from_list(files)
  # puts("#{files.class} - #{files}")
  f = files.flat_map do |file| 
     if File.file?(file) 
      [file, File.read(file)]
     else
      read_files_from_list(Dir.glob(File.join(file,'*')))
     end
  end
 f
end

class GoogleGeminiClient

  def initialize(context_files = [])
    config = YAML.load_file('config.yml')

    @api_key = config['api_key']
    log_file = config['log_file'] || 'gemini_client.log'
    @api_url = config['api_url']
    @context_files = context_files

    @memory = []
    @logger = Logger.new(log_file)
    @request_count = 0
    @token_count = 0
    @request_times = []
    @context_included = false # Flag to track if the context has been included
  end

  def generate_content(prompt)
    file_context = read_files_from_list(@context_files) if @context_files && !@context_included
    @context_included = true if file_context # Mark context as included after the first message

    full_context = compile_context(prompt, file_context)
    token_count = count_tokens(full_context)

    @request_count += 1
    @token_count += token_count
    @request_times << Time.now

    log_request_rate

    request_id = SecureRandom.uuid
    @logger.info("[Request ID: #{request_id}] Sending request ##{@request_count} with #{token_count} tokens.")

    payload = {
      contents: [
        {
          parts: [
            { text: full_context }
          ]
        }
      ]
    }

    url = URI("#{@api_url}?key=#{@api_key}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json

    begin
      response = http.request(request)
      log_request(request_id, payload, response)
      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        save_to_memory(prompt, result)
        # Extract and return the text from the first candidate
        result['candidates']&.dig(0, 'content','parts',0,'text')
      else
        nil # Return nil if the response is not successful
      end
    rescue StandardError => e
      @logger.error("[Request ID: #{request_id}] An error occurred: #{e.message}")
      nil # Return nil in case of errors
    end
  end

  def save_to_memory(prompt, response)
    @memory << { prompt: prompt, response: response }
  end

  def compile_context(prompt, file_context = nil)
    @logger.debug("context: #{file_context}")
    context = @memory.map { |entry| "User: #{entry[:prompt]}\nAI: #{entry[:response]['candidates']&.dig(0, 'content')}" }.join("\n\n")
    context += "\n---\n#{file_context}" if file_context && !file_context.empty?
    context += "\n\nUser: #{prompt}" unless @memory.empty?
    context.empty? ? prompt : context
  end

  def count_tokens(text)
    # Simplistic token count: splitting by spaces as an approximation
    text.split.size
  end

  def log_request_rate
    now = Time.now

    # Remove requests older than a day
    @request_times.reject! { |time| now - time > 86400 }

    requests_per_minute = @request_times.count { |time| now - time <= 60 }
    requests_per_day = @request_times.size
    tokens_per_minute = @token_count / (@request_times.empty? ? 1 : [(now - @request_times.first) / 60.0, 1].max)

    @logger.info("Requests per minute: #{requests_per_minute}")
    @logger.info("Requests per day: #{requests_per_day}")
    @logger.info("Tokens per minute: #{tokens_per_minute.to_i}")
  end

  def log_request(request_id, payload, response)
    @logger.info("[Request ID: #{request_id}] Request Payload: #{payload.to_json}")
    @logger.info("[Request ID: #{request_id}] Response Code: #{response.code}")
    @logger.info("[Request ID: #{request_id}] Response Body: #{response.body}")
  end

  def memory
    @memory
  end
end

# Example usage
if __FILE__ == $0
  context_files = ARGV[0..-1] # Read all arguments as context files
  config_file = 'config.yml'

  client = GoogleGeminiClient.new(context_files)

  loop do
    print "> "
    prompt = STDIN.gets.chomp
    break if prompt.downcase == 'exit'

    response = client.generate_content(prompt)

    if response.nil?
      puts "Failed to generate content."
    else
      puts "\nAI Response:"
      puts response
    end
  end

  puts "\nGoodbye!"
end
