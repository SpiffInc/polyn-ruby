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

RSpec.describe Polyn::Utils::Hash do
  describe "#deep_symbolize_keys" do
    let(:hash) { { "a" => { "b" => { "c" => 1 } } } }
    it "should deep symbolize the keys" do
      expect(described_class.deep_symbolize_keys(hash)).to eq({
        a: {
          b: {
            c: 1,
          },
        },
      })
    end

    let(:hash) { { "a" => { "b" => { "c" => 1 } } } }
    it "should deep symbolize keys in lists" do
      hash = { "a" => { "b" => [{ "c" => 1 }, { "d" => 2 }] } }
      expect(described_class.deep_symbolize_keys(hash)).to eq({
        a: {
          b: [{
            c: 1,
          }, { d: 2 }],
        },
      })
    end

    it "can deep symbolize an array" do
      arr = [{ a: "b" }, { c: "d" }]
      expect(described_class.deep_symbolize_keys(arr)).to eq([{ a: "b" }, { c: "d" }])
    end

    it "should return if not a hash" do
      expect(described_class.deep_symbolize_keys("foo")).to eq("foo")
    end
  end

  describe "#deep_stringify_keys" do
    let(:hash) { { a: { b: { c: 1 } } } }
    it "should deep stringify the keys" do
      expect(described_class.deep_stringify_keys(hash)).to eq({
        "a" => {
          "b" => {
            "c" => 1,
          },
        },
      })
    end

    it "should deep stringify keys in lists" do
      hash = { a: { b: [{ c: 1 }, { d: 2 }] } }
      expect(described_class.deep_stringify_keys(hash)).to eq({
        "a" => {
          "b" => [
            { "c" => 1 },
            { "d" => 2 },
          ],
        },
      })
    end

    it "can deep stringify an array" do
      arr = [{ a: "b" }, { c: "d" }]
      expect(described_class.deep_stringify_keys(arr)).to eq([{ "a" => "b" }, { "c" => "d" }])
    end

    it "should return if not a hash" do
      expect(described_class.deep_stringify_keys("foo")).to eq("foo")
    end
  end

  describe "#deep_camelize_keys" do
    it "should deep camelize the keys" do
      expect(described_class.deep_camelize_keys({ "a_bc_de" => 1 })).to eq({
        "aBcDe" => 1,
      })
    end
  end

  describe "#deep_snake_case_keys" do
    it "should deep snake case the keys" do
      expect(described_class.deep_snake_case_keys({ "aBcDe" => 1 })).to eq({
        "a_bc_de" => 1,
      })
    end
  end
end
