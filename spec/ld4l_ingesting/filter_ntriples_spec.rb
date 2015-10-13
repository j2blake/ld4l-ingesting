require 'spec_helper'

describe Ld4lIngesting::FilterNtriples do
  describe 'the good_syntax() method' do
    it 'accepts a simple object property statement' do
      accept_syntax('<http://test/s> <http://test/o> <http://test/p> .')
    end

    it 'accepts a blank node as subject' do
      accept_syntax('_:bob <http://test/o> <http://test/p> .')
    end

    it 'accepts a plain string literal' do
      accept_syntax('<http://test/s> <http://test/o> "this" .')
    end

    it 'accepts a language literal' do
      accept_syntax('<http://test/s> <http://test/o> "something"@en-US .')
    end

    it 'accepts a typed literal' do
      accept_syntax('<http://test/s> <http://test/o> "literal"^^<http://string> .')
    end
    
    it 'rejects white space in a URI' do
      reject_syntax('<http://test/s> <http://test/o> <http://test/p > .')
    end

    it 'rejects an empty URI' do
      reject_syntax('<http://test/s> <http://test/o> <> .')
    end
        
    def accept_syntax(line)
      expect(subject.good_syntax(line)).to be_truthy
    end

    def reject_syntax(line)
      expect(subject.good_syntax(line)).to be(false)
    end
  end
end
