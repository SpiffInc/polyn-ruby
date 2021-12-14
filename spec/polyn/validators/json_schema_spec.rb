# frozen_string_literal: true

# Copyright 2021-2022 Spiff, Inc.
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

require "spec_helper"

require_relative "../../../lib/polyn/validators/json_schema"

RSpec.describe Polyn::Validators::JsonSchema do
  let(:validator) do
    Polyn::Validators::JsonSchema.new(
      prefix: File.expand_path("../../fixtures", __dir__),
      file:   true,
    )
  end

  describe "#validate" do
    context "when the data is valid" do
      let(:data) do
        {
          "a" => 1,
        "b"  => 30,
        }
      end

      it "returns true" do
        expect(validator.validate("calc.mult", data)).to eq([])
      end
    end

    context "when the data is invalid" do
      let(:data) do
        {
          "name" => "John Doe",
          "age"  => "1",
        }
      end

      it "returns false" do
        expect(validator.validate("calc.mult", data)).to_not be_empty
      end
    end
  end
end
