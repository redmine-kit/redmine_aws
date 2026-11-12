# frozen_string_literal: true

# The AWS administration menu; the other Redmine AWS plugins add their tabs
# under admin/aws.
get 'admin/aws', to: 'aws_admin#index'

get 'admin/aws/status', to: 'aws_status#index', as: 'aws_status'
post 'admin/aws/status/check', to: 'aws_status#check', as: 'aws_status_check'
