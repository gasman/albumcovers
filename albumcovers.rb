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
	
	def self.photos(licenses)
		@flickr_last_fetch ||= {}
		@flickr_photos ||= {}
		
		if @flickr_last_fetch[licenses].nil? or @flickr_last_fetch[licenses] < 1.hour.ago
			@flickr_photos[licenses] = @flickr.photos.search(
				:sort => 'interestingness-desc', :min_upload_date => 7.days.ago.to_i, :per_page => 500, :license => licenses.join(','))
			@flickr_last_fetch[licenses] = Time.now
		end
		@flickr_photos[licenses]
	end
	
	def self.licenses
		if @licenses_last_fetch.nil? or @licenses_last_fetch < 6.hours.ago
			licenses_doc = Hpricot.XML(open("http://api.flickr.com/services/rest/?api_key=#{FLICKR_API_KEY}&method=flickr.photos.licenses.getInfo"))
			@licenses = licenses_doc / 'license'
		end
		@licenses
	end
	
	def self.username(nsid)
		person = Hpricot.XML(open("http://api.flickr.com/services/rest/?api_key=#{FLICKR_API_KEY}&method=flickr.people.getInfo&user_id=#{nsid}"))
		(person % 'username').inner_text
	end
end

module AlbumCovers::Controllers
	class Index < R '/'
		
		DEFAULT_LICENSES = %w(1 2 4 5)
		
		def get
			@licenses = (@input['license'] || DEFAULT_LICENSES).to_a
			
			photos = Flickr.photos(@licenses)
			if photos.total == 0
				photos = Flickr.photos(DEFAULT_LICENSES)
				@warning = true
			end
			@photo = photos[rand(photos.total < 500 ? photos.total : 500)]
			
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
					.heading h1 {
						text-align: center;
						border-bottom: 1px solid #ccc;
					}
					.result {
						float: left;
						width: 440px;
						margin-bottom: 20px;
					}
					.album {
						width: 400px;
						height: 400px;
						border: 1px solid #888;
						position: relative;
						overflow: hidden;
						background-repeat: no-repeat;
						background-position: center;
					}
					.album h1 {
						position: absolute;
						bottom: 20px;
						left: 10px;
						font-size: 32px;
						-webkit-text-stroke: 1px black;
						letter-spacing: -1px;
					}
					.album h2 {
						position: absolute;
						top: 350px;
						left: 15px;
						font-size: 22px;
						-webkit-text-stroke: 0.5px black;
						letter-spacing: -0.5px;
					}
					p.credit {
						font-size: 0.7em;
						color: #666666;
					}
					p.site_credit {
						font-size: 0.7em;
						clear: both;
						background-color: #ccc;
						padding: 4px;
					}
				], :type => 'text/css'
			end
			body do
				self << yield
			end
		end
	end

	def index
		div.heading do
			h1 "Album Cover Generator"
		end
		if @warning
			p "No photos found with the selected licenses! Reverting to default set"
		end
		div.result do
			div.album :style => "background-color: ##{@colour1}; background-image: url(#{@photo.source_url})" do
				h1 @band_name, :style => "color: ##{@colour2}"
				h2 @album_title, :style => "color: ##{@colour3}"
			end
			p.credit do
				text "Picture credit: "
				a "#{Flickr.username(photo.owner)} - \"#{photo.title}\"", :href => @photo.page_url
			end
		end
		form :action => '.', :method => 'get' do
			fieldset do
				legend "Photo licenses to include"
				ul do
					for license in Flickr.licenses
						li do
							if @licenses.include?(license['id'])
								# If there's a better way to do conditional attributes, the Markaby documentation doesn't tell me what it is. FUCK MARKABY.
								input :type => 'checkbox', :name => 'license', :value => license['id'], :id => "license_#{license['id']}", :checked => true
							else
								input :type => 'checkbox', :name => 'license', :value => license['id'], :id => "license_#{license['id']}"
							end
							label license['name'], :for => "license_#{license['id']}"
						end
					end
				end
			end
			input :type => 'submit', :value => "Get another cover"
		end
		p.site_credit do
			text "A "
			a "Matt.West.co.tt", :href => 'http://matt.west.co.tt/'
			text " production. You should "
			a "follow me on Twitter", :href => 'http://twitter.com/westdotcodottt'
			text '.'
		end
	end
end

