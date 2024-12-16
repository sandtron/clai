#!/usr/bin/env ruby
require 'fileutils'
require_relative 'google_gemini_client'

class DocumentWriter
  def initialize(client, output_file)
    @client = client
    @output_file = output_file

    FileUtils.touch(@output_file)
  end

  def write_to_file(content)
    File.write(@output_file, content)
    puts "Document saved to #{@output_file}"
  end

  def iterate
    initial_prompt = """
    1. You are a document writer. Your job is to produce document content. 
    2. You will be provided with the current state of a document and a user instruction. 
    3. Only respond with the plain text content
    4. Your job is to update the document based off of the user instruction. 
    5. Respond with only the entirety of the raw document content. 
    6. Any thoughts or information you wish to add to the response should be included within the document as a comment following the standards of the document type. Prefer to comment inline. 
    7. Your response will be saved directly to the document so it must be a valid document of the desired type. 
    8. Only respond with the raw plain text content
    9. do not apply any formatting
    10. Always maintain the integrity of the document contents
    """
    is_first_request = true
    loop do
      print "> "
      instructions = STDIN.gets.chomp
      break if instructions.downcase == 'exit'

      request = compile_request(instructions)
      
      if is_first_request
        request = initial_prompt+"\n"+request
        is_first_request = false
      end

      response = @client.generate_content(request)

      if response.nil?
        puts "Failed to generate content. Please try again."
      else
        write_to_file(response.strip)
      end
    end

  end

  private

  def compile_request(instructions)
    "DocumentName: #{@output_file}\nDocument:\n#{read_document}\n\nUser Instructions:\n#{instructions}"
  end

  def read_document
    if File.exist?(@output_file)
      File.read(@output_file)
    else
      ""
    end
  end
end

# Example usage
if __FILE__ == $0
  output_file = ARGV[0]
  context_glob = ARGV[1]
  config_file = ARGV[2] || 'config.yml'

  client = GoogleGeminiClient.new(config_file, context_glob)
  writer = DocumentWriter.new(client, output_file)
  writer.iterate
end
