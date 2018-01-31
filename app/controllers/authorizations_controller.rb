class AuthorizationsController < ApplicationController
  
  before_action :set_exchange, only: [:new, :create]
  
  def new
    @authorization = Authorization.new
  end
  
  def create
    @authorization = Authorization.new( authorization_params )
    @authorization.exchange = @exchange
    @authorization.user = current_user
    if @authorization.save
      redirect_to exchanges_path
    else
      flash.now[:alert] = @authorization.errors.full_messages.to_sentence
      @authorization = Authorization.new
      render :new
    end
  end
  
  def destroy
    @authorization = Authorization.find( params[:id] )
    @authorization.destroy
    redirect_to exchanges_path
  end
  
  private
  
  def authorization_params
    params.require( :authorization ).permit( :api_key, :api_secret, :api_pass )
  end
  
  def set_exchange
    @exchange = Exchange.find( params[:exchange_id] )
  end
  
end
