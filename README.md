# clai-doc: Command-Line AI Document Generator

This CLI tool helps you iteratively generate documents using the Google Gemini API.

## Getting Started

1. **Install required gems:**
   ```bash
   gem install net-http json logger yaml securerandom fileutils
   ```

2. **Rename the configuration file:** Rename `config-sample.yml` to `config.yml`.  You'll need to obtain a Google Gemini API key and place it in this file.  See the section on configuration below for details.

3. **Run the program:**
   ```bash
   ruby clai-doc output.txt [context_file1.txt] [context_file2.txt] ...
   ```
   * Replace `output.txt` with the desired name for your output document.
   * Optional context files (`.txt` files) can be added as additional arguments to provide initial content or context for the document generation.


## Configuration (`config.yml`)

The `config.yml` file should contain the following:

```yaml
api_key: "YOUR_API_KEY_HERE"
log_file: "/path/to/your/log/file.log" 
```

Replace `"YOUR_API_KEY_HERE"` with your actual Google Gemini API key and `/path/to/your/log/file.log` with the desired path for log files.


## Usage

The program will prompt you for instructions at each iteration.  Type your instructions and press Enter. To exit, type 'exit'.  The program will save the document to the specified output file after each iteration.


## Example

```bash
ruby clai-doc mydocument.txt introduction.txt
```

This will create a file named `mydocument.txt` and use `introduction.txt` as initial context.  The program will then prompt you to provide instructions to guide the AI in generating the document.


##  Advanced Usage (Context Files)

You can provide one or more context files as input. These files are included in the request to the API and can be used to provide background information or pre-written sections.  The tool will recursively read any files within a given directory structure if provided as context.