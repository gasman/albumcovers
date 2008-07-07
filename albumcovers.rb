require 'camping'
require 'hpricot'
require 'open-uri'

Camping.goes :AlbumCovers

module AlbumCovers::Controllers
  class Index < R '/'
    def get
      flickr_interesting = Hpricot(open('http://www.flickr.com/explore/interesting/7days/'))
      @photo = ((flickr_interesting / 'td.Photo')[2] % 'img')['src']
      @photo.gsub!(/\_m\.jpg$/, '.jpg')
      wikipedia_random = Hpricot(open('http://en.wikipedia.org/wiki/Special:Random'))
      @band_name = (wikipedia_random % 'h1').inner_text
      quotes_random = Hpricot(open('http://www.quotationspage.com/random.php3'))
      @full_quote = ((quotes_random / 'dt.quote').last % 'a').inner_text
      @album_title = @full_quote.match(/(\w+\W+\w+\W+\w+\W+\w+)\W*$/)[1]
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
          	top: 300px;
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
      img :src => @photo
    end
  end
end

