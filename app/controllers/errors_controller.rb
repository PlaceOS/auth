# encoding: UTF-8

class ErrorsController < ApplicationController
  def not_found
    head :not_found
  end
end
