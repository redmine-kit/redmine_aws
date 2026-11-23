# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Aws
    class StatusTest < ActiveSupport::TestCase
      # Plugin ids, and whether each is of the family.
      IDS = {
        redmine_kit_aws: true, redmine_kit_aws_s3: true, 'redmine_kit_aws_costexplorer' => true,
        redmine_kit_awsome: false, redmine_kit_ui: false, redmine_aws: false, redmine_aws_s3: false
      }.freeze

      def test_the_family_is_the_base_and_its_parts
        IDS.each { |id, family| assert_equal family, Status.family?(id), id }
      end

      def test_versions_list_the_plugins_of_the_family_only
        other = Redmine::Plugin.register(:redmine_kit_awsome) do
          name 'Other'
          version '9.9.9'
          directory Rails.root.join('plugins/redmine_kit_aws').to_s
        end
        names = Status.new.versions.map(&:first)

        assert_includes names, 'Redmine Kit AWS'
        assert_not_includes names, other.name
      ensure
        Redmine::Plugin.unregister(:redmine_kit_awsome)
      end

      # A section is values (a label and its rows) or a partial, never both or neither.
      def test_a_status_section_takes_a_label_and_rows_or_a_partial
        rows = -> { [] }
        [{ label: :label_aws_status }, {}, { partial: 'p', label: :label_aws_status }].each do |options|
          assert_raises(ArgumentError, options.inspect) do
            Admin.register_status_section(:wrong, position: 1, **options)
          end
        end
        assert_raises(ArgumentError) { Admin.register_status_section(:wrong, position: 1, partial: 'p', &rows) }
        assert_not Admin.status_sections.map(&:name).include?('wrong')
      end

      def test_sections_give_the_rows_and_leave_out_a_section_without_rows
        view = ApplicationController.new.view_context
        sections = Status.new.sections(view)

        assert_equal %w[versions], sections.pluck(:name)
        assert_equal 'Versions', sections.first[:label]
        rails = sections.first[:rows].detect { |row| row[:name] == 'Rails' }
        assert_equal({ name: 'Rails', value: Rails.version }, rails)
      end
    end
  end
end
