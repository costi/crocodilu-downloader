class Tril < ActiveRecord::Base
  require 'net/http'
  require 'uri'
  
  validates_numericality_of :byte_size, :greater_than => 0
  validates_presence_of :content_type
  validates_presence_of :name
  
  def get_tril_variable(var_name)
    $1 if self.html_page.body =~ /so\.addVariable\(\"#{var_name}\", \"(\w+)\"\);/
  end
  
  def server_no
      @server_no ||= get_tril_variable('server')
  end
  
  def secret_key
    @secret_key ||= get_tril_variable('key')
  end
  
  def html_page
    @html_page ||= begin 
		        logger.info "Fetching #{self.html_page_path} html page..."
		        res = Net::HTTP.start("www.trilulilu.ro", 80) {|http|
			  http.get(self.html_page_path)
    			}
		      end
  end

  def self.factory(url)
    trilu_user, trilu_file_id = url.split('/')[-2, 2]
    if !(tril = Tril.find(:first, :conditions => { :trilu_user => trilu_user, :trilu_file_id => trilu_file_id}))    
      tril = Tril.new
      tril.trilu_user, tril.trilu_file_id = trilu_user, trilu_file_id
      tril.name = $2 if tril.html_page.body =~ /<title>\s*(Audio\s*Muzica\s*-\s*)*(.*)<\/title>/i
    end
    return tril
  end

  
  def remote_file_path 
    "/stream.php?type=audio&hash=#{trilu_file_id}&username=#{trilu_user}&key=#{secret_key}"  
  end

  def local_file_path
    File.join(RAILS_ROOT,'public','files',name.tr("/\000\\", "") +".mp3")    
  end
  
  def html_page_path
    "/#{trilu_user}/#{trilu_file_id}"
  end
  
  def server_name 
    "fs#{server_no}.trilulilu.ro"
  end

  def fetch
      Net::HTTP.start(server_name, 80){ |http|
          http.request_get(remote_file_path) { |response|
	    self.byte_size = response['content-length']
	    self.content_type = response['content-type']
	    
	    if(self.created_on && File.exists?(self.local_file_path) && File.size(self.local_file_path) == self.byte_size)
	      f = File.open(self.local_file_path, 'rb')
	      while buffer = f.read(8192)
    		yield(buffer)
	      end
	      f.close
	    else 
	        logger.info "saving file on #{local_file_path}"
    		f = File.open(local_file_path, 'wb')
	        response.read_body { |buffer|
        	  yield(buffer)
    	          f.write buffer
                }
                f.close
	    end
          }
	  self.save
          logger.info 'Done'
      }
  end
  
  def before_destroy
    File.unlink(self.local_file_path)
  end  
  
end
