require 'spec_helper'

describe Ld4lIngesting::FilterNtriples do
  describe 'the parse_line() method' do
    it 'parses a line' do
      expect(subject.parse_line('a b c .')).to be_truthy
    end
  end
  
  describe 'the good_uri() method' do
    it 'accepts an explicit URI' do
      expect(subject.good_uri('<http://test/s>')).to be_truthy
    end
    it 'rejects an explicit URI with no leading bracket' do
      expect(subject.good_uri('http://test/s>')).to be(false)
    end
    it 'rejects an explicit URI with no trailing bracket' do
      expect(subject.good_uri('<http://test/s')).to be(false)
    end
    it 'rejects an explicit URI with bad characters' do
      expect(subject.good_uri('<http://test/\\s>')).to be(false)
    end
    it 'accepts a prefixed URI' do
      expect(subject.good_uri('prefix:localname')).to be_truthy
    end
    it 'rejects an prefixed URI with bad characters' do
      expect(subject.good_uri('prefix:localname\\')).to be(false)
    end
  end
  
  describe 'the good_syntax() method' do
    it 'accepts a simple object property statement' do
      accept_syntax('<http://test/s> <http://test/o> <http://test/p> .')
    end

    it 'accepts a prefix in the subject' do
      accept_syntax('test:s <http://test/o> <http://test/p> .')
    end

    it 'accepts a prefix in the predicate' do
      accept_syntax('<http://test/s> test:o <http://test/p> .')

    end

    it 'accepts a prefix in the object' do
      accept_syntax('<http://test/s> <http://test/o> test:p .')
    end

    it 'accepts a numeric literal' do
      accept_syntax('<http://test/s> <http://test/o> 4 .')
    end

    it 'accepts a plain string literal' do
      accept_syntax('<http://test/s> <http://test/o> "this" .')
    end

    it 'accepts a language literal' do
      accept_syntax('<http://test/s> <http://test/o> "something"@US_en .')
    end

    it 'accepts a typed literal' do
      accept_syntax('<http://test/s> <http://test/o> "literal"^^http://string .')
    end
    
    def accept_syntax(line)
      expect(subject.good_syntax(line)).to be(true)
    end
  end
end
