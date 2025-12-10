#!/usr/bin/env ruby
# frozen_string_literal: true

module Overcommit
  module Hook
    module PrePush
      # Prevents pushes to protected branches
      class ProtectedBranchCheck < Base
        PROTECTED_BRANCHES = %w[master main dragula production staging].freeze

        def run
          return :pass if pushed_refs.empty?

          protected_pushes = pushed_refs.select do |pushed_ref|
            remote_branch = pushed_ref.remote_ref.split('/').last
            PROTECTED_BRANCHES.include?(remote_branch)
          end

          return :pass if protected_pushes.empty?

          remote_branch = protected_pushes.first.remote_ref.split('/').last

          error_message = <<~ERROR

            ❌ ERROR: Direct push to '#{remote_branch}' is not allowed!

            You are trying to push to a protected branch.

            Please follow the proper workflow:
              1. Create a feature branch:
                 git checkout -b feature/your-feature-name
              2. Cherry-pick or commit your changes to the feature branch
              3. Push the feature branch:
                 git push -u origin feature/your-feature-name
              4. Create a Pull Request:
                 gh pr create --title "Title" --body "Description"

            If you already committed to #{remote_branch} by mistake:
              1. Create a feature branch from current state:
                 git checkout -b feature/your-feature-name
              2. Reset #{remote_branch} to origin:
                 git checkout #{remote_branch}
                 git reset --hard origin/#{remote_branch}
              3. Go back to your feature branch and push:
                 git checkout feature/your-feature-name
                 git push -u origin feature/your-feature-name
              4. Create a PR from the feature branch

            See AGENTS.md for complete workflow details.

          ERROR

          [:fail, error_message]
        end
      end
    end
  end
end
