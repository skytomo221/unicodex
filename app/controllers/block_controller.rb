class BlockController < ApplicationController
  def show
    @block = BlockRecord.all.find { |r| r.normalized_name == params[:name] }
  end
end
