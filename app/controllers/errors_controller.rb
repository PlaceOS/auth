# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    head :not_found
  end
end
