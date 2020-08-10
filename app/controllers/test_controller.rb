# encoding: UTF-8


class TestController < ApplicationController
  def index
    render json: { hello: "world" }
  end

  def show
    raise "runtime error :("
  end
end
