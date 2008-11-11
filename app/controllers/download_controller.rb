class DownloadController < ApplicationController
 
  def index
    render :action => :submit_tril
  end
  
  def submit_tril    
    if params[:file]
      redirect_to :action => :download, :url => params[:file][:url]
    end
  end
  
  def download
    if params[:url]
      tril = Tril.factory(params[:url])
      @performed_render = false
      response.headers.update(
          'Content-Type' => tril.content_type,
          'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition'       => "attachment; filename=\"#{File.basename(tril.name)}.mp3\"",
          'Content-Length' => tril.byte_size)
      render :text => proc { |response, output| tril.fetch { |buffer| output.write(buffer) } }
      tril.save # This save will fail because it will be done too early and we don't have the content type and length. 
      # I save after the fetch function in the model
    end
  end
  
  def history
    @pages, @trils = paginate :trils, :order => 'updated_on DESC', :per_page => 20
  end
  
  def destroy
    if request.post?
      Tril.find(params[:id]).destroy
    end    
    redirect_to :action => :cache
  end  
  
  
end
