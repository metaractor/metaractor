describe Metaractor do
  describe Metaractor::Parameters do
    let(:param_test_class) do
      Class.new do
        include Metaractor

        required :foo

        validate_parameters do
          # Conditionally required parameter
          if context.foo == :bar && context.bar.nil?
            require_parameter :bar, message: "required when foo is bar"
          end

          if context.foo == :deadbeef
            add_parameter_error param: :foo, message: "is invalid"
          end

          context.validate_has_run = true
        end

        before :before_hook
        def before_hook
          raise "validate has not run" unless context.validate_has_run
        end

        before do
          # Use bang method outside of the validate_parameters block
          require_parameter! :awesome if context.foo == :awesome
        end

        def call
        end
      end
    end
    let(:param_test) { param_test_class.new }

    it "fails without required parameters" do
      result = param_test_class.call
      expect(result).to be_failure
      expect(result).to_not be_valid
    end

    context "custom validation" do
      it "runs validate_parameters hook before the before hooks" do
        result = param_test_class.call(foo: :bar, bar: true)
        expect(result).to be_success
      end

      it "marks the interactor as failed and invalid with require_parameter" do
        result = param_test_class.call(foo: :bar)
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to include "bar required when foo is bar"
      end

      it "marks the interactor as failed and invalid with add_parameter_error" do
        result = param_test_class.call(foo: :deadbeef)
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to include "foo is invalid"
      end

      it "marks the interactor as failed and invalid with require_parameter!" do
        result = param_test_class.call(foo: :awesome)
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to include "Required parameters: awesome"
      end
    end

    context "blank values" do
      let(:blank_class) do
        Class.new do
          include Metaractor

          parameter :special, allow_blank: true

          def call
            context.keys = context.to_h.keys
          end
        end
      end

      it "removes the empty string" do
        result = blank_class.call(foo: "")
        expect(result.keys).to_not include :foo
      end

      it "removes a whitespace string" do
        result = blank_class.call(foo: "  ")
        expect(result.keys).to_not include :foo
      end

      it "removes nil" do
        result = blank_class.call(foo: nil)
        expect(result.keys).to_not include :foo
      end

      it "does not remove false" do
        result = blank_class.call(foo: false)
        expect(result.keys).to include :foo
      end

      it "does not remove []" do
        result = blank_class.call(foo: [])
        expect(result.keys).to include :foo
      end

      it "does not remove {}" do
        result = blank_class.call(foo: {})
        expect(result.keys).to include :foo
      end

      it "does not remove whitelisted param" do
        result = blank_class.call(foo: "", special: nil)
        expect(result.keys).to_not include :foo
        expect(result.keys).to include :special
      end
    end

    context "parameter defaults" do
      let(:defaults_class) do
        Class.new do
          include Metaractor

          required :name
          parameter :foo, default: -> { context.name }
          optional :bar, default: "a string"
          optional :shared_default, default: "a string"
          optional :boolean_default, default: false

          def call
          end
        end
      end

      it "applies defaults" do
        result = defaults_class.call!(name: "Best Defaults")
        expect(result.foo).to eq "Best Defaults"
        expect(result.bar).to eq "a string"
        expect(result.shared_default).to eq "a string"
        expect(result.boolean_default).to eq false

        result.bar = "different"
        expect(result.bar).to eq "different"
        expect(result.shared_default).to eq "a string"
      end
    end

    context "chained OR required parameters" do
      let(:param_test_class) do
        Class.new do
          include Metaractor

          required or: [:token, or: [:recipient_id, :recipient]]

          def call
          end
        end
      end
      let(:recipient) { double(:recipient) }

      it "is valid with token" do
        result = param_test_class.call(token: "asdf")
        expect(result).to be_success
      end

      it "is valid with recipient id" do
        result = param_test_class.call(recipient_id: 1)
        expect(result).to be_success
      end

      it "is valid with recipient" do
        result = param_test_class.call(recipient: recipient)
        expect(result).to be_success
      end

      it "is valid with token and recipient id" do
        result = param_test_class.call(token: "asdf", recipient_id: 1)
        expect(result).to be_success
      end

      it "is valid with recipient id and recipient" do
        result = param_test_class.call(recipient_id: 1, recipient: recipient)
        expect(result).to be_success
      end

      it "is invalid without parameters" do
        result = param_test_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to include "Required parameters: (token or (recipient_id or recipient))"
      end
    end

    context "chained OR and AND required parameters" do
      let(:param_test_class) do
        Class.new do
          include Metaractor

          required or: [:token, and: [:recipient_id, :recipient]]

          def call
          end
        end
      end
      let(:recipient) { double(:recipient) }

      it "is valid with token" do
        result = param_test_class.call(token: "asdf")
        expect(result).to be_success
      end

      it "is valid with recipient_id and recipient" do
        result = param_test_class.call(recipient_id: 1, recipient: recipient)
        expect(result).to be_success
      end

      it "is not valid with recipient_id" do
        result = param_test_class.call(recipient_id: 1)
        expect(result).to be_failure
      end

      it "is invalid without parameters" do
        result = param_test_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to include "Required parameters: (token or (recipient_id and recipient))"
      end
    end

    context "chained XOR required parameters" do
      let(:param_test_class) do
        Class.new do
          include Metaractor

          required xor: [:token, :all]

          def call
          end
        end
      end
      let(:recipient) { double(:recipient) }

      it "is valid with token" do
        result = param_test_class.call(token: "asdf")
        expect(result).to be_success
      end
      it "is valid with all" do
        result = param_test_class.call(all: true)
        expect(result).to be_success
      end

      it "is not valid with token and all" do
        result = param_test_class.call(token: "asdf", all: true)
        expect(result).to be_failure
      end

      it "is invalid without parameters" do
        result = param_test_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to include "Required parameters: (token xor all)"
      end
    end

    context "parameter options" do
      let(:options_class) do
        Class.new do
          include Metaractor

          required or: [:token, or: [:recipient_id, :recipient]]
          parameter :token, allow_blank: true
          parameter :thing, required: true
          required :foo, allow_blank: true
          optional :bar, default: "a string"
          optional :baz, default: "a string", allow_blank: true

          def call
            context.keys = context.to_h.keys
          end
        end
      end

      it "correctly tracks declared parameters" do
        action = options_class.new

        expect(action.requirement_trees).to contain_exactly({
          or: [:token, or: [:recipient_id, :recipient]]
        })
        tree = action.requirement_trees.first

        expect(action.parameters).to eq(
          token: Metaractor::Parameters::Parameter.new(:token, allow_blank: true, required: tree),
          recipient_id: Metaractor::Parameters::Parameter.new(:recipient_id, required: tree),
          recipient: Metaractor::Parameters::Parameter.new(:recipient, required: tree),
          thing: Metaractor::Parameters::Parameter.new(:thing, required: true),
          foo: Metaractor::Parameters::Parameter.new(:foo, required: true, allow_blank: true),
          bar: Metaractor::Parameters::Parameter.new(:bar, default: "a string"),
          baz: Metaractor::Parameters::Parameter.new(:baz, default: "a string", allow_blank: true)
        )
      end

      it "fails without required parameters" do
        result = options_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.error_messages).to contain_exactly(
          "Required parameters: (token or (recipient_id or recipient))",
          "Required parameters: thing",
          "Required parameters: foo"
        )
      end

      it "removes blank params" do
        result = options_class.call!(token: "", thing: "asdf", foo: "", extra: nil, baz: "")
        expect(result.keys).to include(:token, :thing, :foo, :baz)
      end

      it "sets defaults" do
        result = options_class.call!(token: "", thing: "asdf", foo: "")
        expect(result.bar).to eq "a string"
      end
    end

    context "parameter types" do
      let(:types_class) do
        Class.new do
          include Metaractor

          required :foo, type: ->(value) { value.to_s }
          optional :job_title,
            :job_title_required,
            type: :boolean

          optional :boom,
            allow_blank: true,
            type: ->(value) { raise "BOOM" if value.nil? }

          def call
          end
        end
      end

      before do
        Metaractor.register_type(
          :boolean,
          ->(value) { ActiveModel::Type::Boolean.new.cast(value) }
        )
      end

      after do
        Metaractor.clear_types!
      end

      it "casts types from a callable" do
        result = types_class.call(
          foo: :a_symbol
        )
        expect(result.foo).to eq "a_symbol"
      end

      it "casts types from a configured type" do
        result = types_class.call(
          foo: :a_symbol,
          job_title: "1",
          job_title_required: "false"
        )
        expect(result.job_title).to eq true
        expect(result.job_title_required).to eq false
      end

      context "with allow_blank" do
        let(:types_class) do
          Class.new do
            include Metaractor

            optional :boom,
              allow_blank: true,
              type: ->(value) { raise "BOOM" if value.nil? }

            optional :pow, type: ->(value) { raise "POW" if value.nil? }

            def call
            end
          end
        end

        it "does not typecast nil values" do
          result = types_class.call(
            boom: nil,
            pow: nil
          )

          expect(result.boom).to eq nil
          expect(result).to_not have_key(:pow)
        end
      end
    end

    context "structured errors" do
      let(:error_test_class) do
        Class.new do
          include Metaractor

          optional :is_admin
          optional :user

          def call
            fail_with_error!(
              errors: {
                base: "Invalid configuration",
                is_admin: "must be true or false",
                user: [title: "cannot be blank", username: ["must be unique", "must not be blank"]]
              }
            )
          end
        end
      end

      it "fails with a structured error" do
        result = error_test_class.call
        expect(result).to be_failure

        expect(result.errors).to include({
          base: "Invalid configuration",
          is_admin: "must be true or false",
          user: {
            title: "cannot be blank",
            username: ["must be unique", "must not be blank"]
          }
        })

        expect(result.errors).to include(:is_admin, [:user, :title])

        expect(result.errors).to include(
          "Invalid configuration",
          "is_admin must be true or false",
          "user.title cannot be blank",
          "user.username must be unique",
          "user.username must not be blank"
        )

        expect(result.error_messages).to include(
          "Invalid configuration",
          "is_admin must be true or false",
          "user.title cannot be blank",
          "user.username must be unique",
          "user.username must not be blank"
        )

        expect(result.errors).to contain_exactly(
          "Invalid configuration",
          "is_admin must be true or false",
          "user.title cannot be blank",
          "user.username must be unique",
          "user.username must not be blank"
        )

        expect(result).to include_errors(
          "username must be unique",
          "username must not be blank"
        ).at_path(:user, :username)

        expect(result).to include_errors("user.title cannot be blank")

        expect(result.errors.full_messages_for(:user)).to include(
          "title cannot be blank",
          "username must be unique",
          "username must not be blank"
        )

        expect(result.errors.full_messages_for(:user, :title)).to include(
          "title cannot be blank"
        )

        expect(result.errors.full_messages_for(:user, :username)).to include(
          "username must be unique",
          "username must not be blank"
        )

        expect(result.errors[:user, :username]).to include "must be unique"
        expect(result.errors.dig(:user, :username)).to include "must be unique"
      end

      it "allows slicing the errors by path" do
        result = error_test_class.call
        expect(result).to be_failure

        expect(
          result.errors.slice(:base, [:user, :title])
        ).to eq({
          base: "Invalid configuration",
          user: {title: "cannot be blank"}
        })
      end

      it "handles a delegated error hash" do
        messages = SimpleDelegator.new({user: SimpleDelegator.new(["must be awesome"])})

        errors = Metaractor::Errors.new
        expect { errors.add(errors: messages) }.to_not raise_error

        expect(errors).to include(
          user: "must be awesome"
        )
      end
    end

    context "i18n" do
      let(:test_class) do
        Class.new do
          include Metaractor

          def self.name
            "Authorization::Roles::CheckRole"
          end

          optional :role, :user

          def call
            fail_with_error!(
              errors: {
                base: :internal_error,
                role: :mismatched_role,
                user: :blank
              }
            )
          end
        end
      end

      let(:top_level_error) do
        store_translations(
          :en,
          errors: {
            parameters: {
              blank: "%{parameter} cannot be blank",
              internal_error: "Internal Error",
              role: {
                mismatched_role: "Least specific error"
              }
            }
          }
        )
      end

      let(:authorization_error) do
        store_translations(
          :en,
          errors: {
            authorization: {
              parameters: {
                role: {
                  mismatched_role: "Authorization specific error"
                }
              }
            }
          }
        )
      end

      let(:roles_error) do
        store_translations(
          :en,
          errors: {
            authorization: {
              roles: {
                parameters: {
                  role: {
                    mismatched_role: "Super specific error"
                  }
                }
              }
            }
          }
        )
      end

      let(:loaded_translations) do
        [:top_level_error, :authorization_error, :roles_error]
      end

      before do
        loaded_translations.each do |t|
          send(t)
        end

        I18n.default_locale = :en
      end

      after do
        I18n.backend.reload!
      end

      it "correctly uses i18n to generate an error message" do
        result = test_class.call
        expect(result).to be_failure

        expect(result).to include_errors("user cannot be blank")
        expect(result).to include_errors("Internal Error")
        expect(result.errors).to include(:role)
        expect(result).to include_errors("Super specific error")
      end

      context "without the roles message" do
        let(:loaded_translations) do
          [:top_level_error, :authorization_error]
        end

        it "uses the authorization message" do
          result = test_class.call
          expect(result).to be_failure

          expect(result.errors).to include(:role)
          expect(result).to include_errors("Authorization specific error")
        end
      end

      context "without either the roles or authorization messages" do
        let(:loaded_translations) do
          [:top_level_error]
        end

        it "uses the top level message" do
          result = test_class.call
          expect(result).to be_failure

          expect(result.errors).to include(:role)
          expect(result).to include_errors("Least specific error")
        end
      end
    end

    context "nested failures" do
      let(:child) do
        Class.new do
          include Metaractor

          required :a_param

          def call
            fail_with_error!(message: "BOOM")
          end
        end
      end

      let(:parent) do
        Class.new do
          include Metaractor

          required :child
          optional :a_param

          def call
            context.child.call!(a_param: context.a_param)
          end
        end
      end

      let(:simple) do
        Class.new do
          include Metaractor
        end
      end

      let(:organizer) do
        Class.new do
          include Metaractor
          include Interactor::Organizer
        end
      end

      it "fails the parent context" do
        result = parent.call(child: child, a_param: :foo)
        expect(result).to be_failure
        expect(result.error_messages).to include "BOOM"
      end

      it "invalidates the parent context" do
        result = parent.call(child: child)
        expect(result).to be_failure
        expect(result).to be_invalid
        expect(result.error_messages).to include "Required parameters: a_param"
      end

      it "allows organizers to run normally" do
        organizer.organize(simple)
        result = organizer.call(a_param: :foo)
        expect(result).to be_success
      end

      it "allows organizers to fail normally" do
        organizer.organize(child)
        result = organizer.call(a_param: :foo)
        expect(result).to be_failure
        expect(result.error_messages).to eq ["BOOM"]
      end

      it "allows organizers to invalidate normally" do
        organizer.organize(child)
        result = organizer.call
        expect(result).to be_failure
        expect(result.error_messages).to include "Required parameters: a_param"
      end
    end

    describe "Context#has_key?" do
      let(:result) do
        Interactor::Context.new(foo: "bar", blank: "", nope: nil)
      end

      it "correctly identifies existing keys" do
        expect(result.has_key?(:foo)).to be_truthy
        expect(result.has_key?("foo")).to be_truthy
        expect(result.has_key?(:blank)).to be_truthy
        expect(result.has_key?(:nope)).to be_truthy

        expect(result.has_key?(:bar)).to be_falsy
      end
    end

    context "Interactor::Failure output" do
      let!(:chained_class) do
        Class.new do
          include Metaractor

          def self.name
            "Chained"
          end

          def call
            context.chained = true
          end
        end
      end

      let!(:another_class) do
        Class.new do
          include Metaractor

          def self.name
            "Another"
          end

          def call
            context.another = true
          end
        end
      end

      let!(:failure_output_class) do
        Class.new do
          include Metaractor

          required :chained_class
          required :another_class

          def call
            context.parent = true
            context.chained_class.call!(context)
            context.another_class.call!(context)

            context.delete_field(:chained_class)
            context.delete_field(:another_class)

            fail_with_error!(message: "NOPE")
          end
        end
      end

      # Make sure we're using the default formatter
      around do |example|
        current_formatter = Metaractor.hash_formatter
        Metaractor.hash_formatter = Metaractor.default_hash_formatter
        example.run
      ensure
        Metaractor.hash_formatter = current_formatter
      end

      it "gives helpful output" do
        failure_output_class.call!(
          chained_class: chained_class,
          another_class: another_class
        )
      rescue Interactor::Failure => e
        output = e.to_s
        expect(output).to eq "Errors:\n{:base=>\"NOPE\"}\n\nPreviously Called:\nChained\nAnother\n\nContext:\n{:parent=>true, :chained=>true, :another=>true}"
      end
    end
  end
end
