require 'camping'
require 'hpricot'
require 'open-uri'
require 'activesupport'
require 'net/flickr'

require 'config'

Camping.goes :AlbumCovers

module Wikipedia
	def self.random_title
		wikipedia_random = Hpricot(open('http://en.wikipedia.org/wiki/Special:Random'))
		(wikipedia_random % 'h1').inner_text
	end
end

module QuotationsPage
	def self.random_quote
		quotes_random = Hpricot(open('http://www.quotationspage.com/random.php3'))
		((quotes_random / 'dt.quote').last % 'a').inner_text
	end
end

module Flickr
	@flickr = Net::Flickr.new(FLICKR_API_KEY)
	def self.photos
		if @flickr_last_fetch.nil? or @flickr_last_fetch < 1.hour.ago
			@flickr_photos = @flickr.photos.search(
				:sort => 'interestingness-desc', :min_upload_date => 7.days.ago.to_i, :per_page => 500)
			@flickr_last_fetch = Time.now
		end
		@flickr_photos
	end
end

module AlbumCovers::Controllers
	class Index < R '/'
		
		def get
			@photo = Flickr.photos[rand(500)]
			
			@band_name = Wikipedia.random_title
			@album_title = QuotationsPage.random_quote.match(/(\w+\W+\w+\W+\w+\W+\w+)\W*$/)[1]
			
			@colour1 = rand(0xffffff).to_s(16)
			@colour2 = rand(0xffffff).to_s(16)
			@colour3 = rand(0xffffff).to_s(16)
			render :index
		end
	end
end

module AlbumCovers::Views
	def layout
		html do
			head do
				title 'Album Cover Generator'
				style %q[
					html {
						font-family: helvetica, arial, sans-serif;
					}
					.album {
						width: 400px;
						height: 400px;
						border: 1px solid #888;
						position: relative;
						overflow: hidden;
					}
					.album h1 {
						position: absolute;
						bottom: 20px;
						left: 10px;
						font-size: 30px;
					}
					.album h2 {
						position: absolute;
						top: 350px;
						left: 15px;
						font-size: 20px;
					}
				], :type => 'text/css'
			end
			body do
				self << yield
			end
		end
	end

	def index
		div :class => 'album', :style => "background-color: ##{@colour1}" do
			h1 @band_name, :style => "color: ##{@colour2}"
			h2 @album_title, :style => "color: ##{@colour3}"
			img :src => @photo.source_url
		end
	end
end

