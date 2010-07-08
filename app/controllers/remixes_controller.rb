class RemixesController < ApplicationController

  before_filter :login_required, :except => [:index, :show]

  def index
    @remixes = Remix.paginate :page => params[:page], :order => params[:sort] || "created_at DESC"
  end

  def show
    @remix = Remix.find(params[:id])
    @page_title = "#{@remix.user.name} - #{@remix.title}"
  end

  def new
    @remix = Remix.new
    @page_title = "Upload Your Remix"
  end

  def create
    
    @remix = Remix.new(:user_id => current_user[:id])
    @remix.attributes = params[:remix]
    
    if @remix.valid?
    
      new_track = current_user.soundcloud.Track.new
      new_track.title = @remix.title
      new_track.asset_data = @remix.file
      new_track.artwork_data = File.new("#{RAILS_ROOT}/public/images/artwork.jpg")
      new_track.description = SETTINGS["remix"]["description"]
      new_track.sharing = "public"
      new_track.tag_list = SETTINGS["remix"]["tag_list"]
      new_track.track_type = "remix"
    
      if new_track.save
      
        @remix.track_id = new_track.id
        @remix.save
      
        current_user.token.put("/groups/#{SETTINGS["group_id"]}/contributions/#{new_track.id}")
      
        respond_to do |format|
          format.html{ redirect_to remix_url(@remix) }
          format.js{ render :js => "top.location.href = '#{remix_path(@remix)}';" }
        end
      
      end
      
    else
      
      respond_to do |format|
        format.html{ render :action => "new" }
        format.js{ render :js => "top.location.href = '/remixes/new';" }
      end
      
    end
    
  end
  
  def status
    
    remix = Remix.find(params[:id])
    
    if remix.available?
    
      render :update do |page|
        page << "check_var = false;"
        page.replace_html 'processor', :partial => "player", :locals => {:remix => remix}
      end
    
    else
      
      render :nothing => true
      
    end
    
  end

end
