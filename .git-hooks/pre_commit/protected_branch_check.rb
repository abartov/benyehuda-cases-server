#!/usr/bin/env ruby
# frozen_string_literal: true

module Overcommit
  module Hook
    module PreCommit
      # Prevents commits to protected branches
      class ProtectedBranchCheck < Base
        PROTECTED_BRANCHES = %w[master main dragula production staging].freeze

        def run
          current_branch = Overcommit::GitRepo.current_branch

          return :pass unless PROTECTED_BRANCHES.include?(current_branch)

          error_message = <<~ERROR

            ❌ ERROR: Direct commits to '#{current_branch}' are not allowed!

            Please follow the proper workflow:
              1. Create a feature branch:
                 git checkout -b feature/your-feature-name
              2. Make your commits on the feature branch
              3. Push the feature branch:
                 git push -u origin feature/your-feature-name
              4. Create a Pull Request:
                 gh pr create --title "Title" --body "Description"

            If you need to move your changes to a new branch:
              git stash
              git checkout -b feature/your-feature-name
              git stash pop

          ERROR

          [:fail, error_message]
        end
      end
    end
  end
end
