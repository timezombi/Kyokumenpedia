require 'board'
class WikipostsController < ApplicationController

  def index
    if (params[:position_id])
      @wikiposts = Wikipost.includes(:position).where(:position_id => params[:position_id]).order('id desc').limit(50)
      @list_title = "編集履歴"
      @without_position = true
    elsif (params[:user_id])
      @wikiposts = Wikipost.includes(:position).where(:user_id => params[:user_id]).order('id desc').limit(50)
      user = User.find_by(id: params[:user_id])
      @list_title = user.username + "さんのコントリビューション"
      @without_user = true
    else
      @wikiposts = Wikipost.includes(:position).order('id desc').limit(50)
      @list_title = "最新の編集"
    end
  end
  
  def show
    @wikipost = Wikipost.find_by(id: params[:id])
  end

  def likers
    @wikipost = Wikipost.includes(:likers).find_by(id: params[:id])
  end

end
