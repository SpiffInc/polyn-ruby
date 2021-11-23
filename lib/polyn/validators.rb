# frozen_string_literal: true

# Copyright 2021-2022 Jarod Reid
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "addressable"

##
# Validators are used to validate messages being broadcasted to and from Polyn
# Applications.
module Validators
  # Regex detects if string is a URI
  URI_REGEX = %r{^\w+://.+}.freeze

  def self.for(config)
    if config.is_a?(String) && URI_REGEX.match?(config)
      for_uri(config)
    else
      raise ArgumentError, "Invalid URI"
    end
  end

  def self.for_uri(uri)
    uri = Addressable::URI.parse(uri)

    case uri.scheme
    when "file"
      for_file(uri.path, uri.extname)
    end
  end

  def self.for_file(path, extension)
    case extension
    when ".json"
      require "json-schema"
      load File.expand_path("validators/json_schema_file.rb", __dir__)
      Polyn::Validators::JsonSchemaFile.new(
        File.expand_path(path),
      )
    end
  end
end
