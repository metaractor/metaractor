describe Metaractor do
  describe Metaractor::Parameters do
    let(:param_test_class) do
      Class.new do
        include Metaractor

        required :foo

        validate_parameters do
          # Conditionally required parameter
          if context.foo == :bar && context.bar.nil?
            require_parameter :bar, message: 'required when foo is bar'
          end

          if context.foo == :deadbeef
            add_parameter_error param: :foo, message: 'is invalid'
          end

          context.validate_has_run = true
        end

        before :before_hook
        def before_hook
          raise 'validate has not run' unless context.validate_has_run
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

    it 'fails without required parameters' do
      result = param_test_class.call
      expect(result).to be_failure
      expect(result).to_not be_valid
    end

    context 'custom validation' do
      it 'runs validate_parameters hook before the before hooks' do
        result = param_test_class.call(foo: :bar, bar: true)
        expect(result).to be_success
      end

      it 'marks the interactor as failed and invalid with require_parameter' do
        result = param_test_class.call(foo: :bar)
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.errors).to include 'bar required when foo is bar'
      end

      it 'marks the interactor as failed and invalid with add_parameter_error' do
        result = param_test_class.call(foo: :deadbeef)
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.errors).to include 'foo is invalid'
      end

      it 'marks the interactor as failed and invalid with require_parameter!' do
        result = param_test_class.call(foo: :awesome)
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.errors).to include 'Required parameters: awesome'
      end
    end

    context 'blank values' do
      let(:blank_class) do
        Class.new do
          include Metaractor

          def call
            context.keys = context.to_h.keys
          end
        end
      end

      it 'removes the empty string' do
        result = blank_class.call(foo: '')
        expect(result.keys).to_not include :foo
      end

      it 'removes a whitespace string' do
        result = blank_class.call(foo: '  ')
        expect(result.keys).to_not include :foo
      end

      it 'removes nil' do
        result = blank_class.call(foo: nil)
        expect(result.keys).to_not include :foo
      end

      it 'does not remove false' do
        result = blank_class.call(foo: false)
        expect(result.keys).to include :foo
      end

      it 'does not remove []' do
        result = blank_class.call(foo: [])
        expect(result.keys).to include :foo
      end

      it 'does not remove {}' do
        result = blank_class.call(foo: {})
        expect(result.keys).to include :foo
      end
    end

    context 'chained OR required parameters' do
      let(:param_test_class) do
        Class.new do
          include Metaractor

          required or: [:token, or: [:recipient_id, :recipient] ]

          def call
          end
        end
      end
      let(:recipient) { double(:recipient) }

      it 'is valid with token' do
        result = param_test_class.call(token: 'asdf')
        expect(result).to be_success
      end

      it 'is valid with recipient id' do
        result = param_test_class.call(recipient_id: 1)
        expect(result).to be_success
      end

      it 'is valid with recipient' do
        result = param_test_class.call(recipient: recipient)
        expect(result).to be_success
      end

      it 'is valid with token and recipient id' do
        result = param_test_class.call(token: 'asdf', recipient_id: 1)
        expect(result).to be_success
      end

      it 'is valid with recipient id and recipient' do
        result = param_test_class.call(recipient_id: 1, recipient: recipient)
        expect(result).to be_success
      end

      it 'is invalid without parameters' do
        result = param_test_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.errors).to include 'Required parameters: (token or (recipient_id or recipient))'
      end
    end

    context 'chained OR and AND required parameters' do
      let(:param_test_class) do
        Class.new do
          include Metaractor

          required or: [:token, and: [:recipient_id, :recipient] ]

          def call
          end
        end
      end
      let(:recipient) { double(:recipient) }

      it 'is valid with token' do
        result = param_test_class.call(token: 'asdf')
        expect(result).to be_success
      end

      it 'is valid with recipient_id and recipient' do
        result = param_test_class.call(recipient_id: 1, recipient: recipient)
        expect(result).to be_success
      end

      it 'is not valid with recipient_id' do
        result = param_test_class.call(recipient_id: 1)
        expect(result).to be_failure
      end

      it 'is invalid without parameters' do
        result = param_test_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.errors).to include 'Required parameters: (token or (recipient_id and recipient))'
      end
    end

    context 'chained XOR required parameters' do
      let(:param_test_class) do
        Class.new do
          include Metaractor

          required xor: [:token, :all]

          def call
          end
        end
      end
      let(:recipient) { double(:recipient) }

      it 'is valid with token' do
        result = param_test_class.call(token: 'asdf')
        expect(result).to be_success
      end
      it 'is valid with all' do
        result = param_test_class.call(all: true)
        expect(result).to be_success
      end

      it 'is not valid with token and all' do
        result = param_test_class.call(token: 'asdf', all: true)
        expect(result).to be_failure
      end

      it 'is invalid without parameters' do
        result = param_test_class.call
        expect(result).to be_failure
        expect(result).to_not be_valid
        expect(result.errors).to include 'Required parameters: (token xor all)'
      end
    end

    context 'structured errors' do
      let(:error_test_class) do
        Class.new do
          include Metaractor

          optional :user

          def call
            fail_with_error!(
              source: '/user',
              title: 'Bad user'
            )
          end
        end
      end

      it 'fails with a structured error' do
        result = error_test_class.call
        expect(result).to be_failure

        expect(result.errors).to include({
          source: '/user',
          title: 'Bad user'
        })

        expect(result.error_messages).to include(
          '/user: Bad user'
        )
      end
    end

    context 'nested failures' do
      let(:child) do
        Class.new do
          include Metaractor

          required :a_param

          def call
            fail_with_error!(message: 'BOOM')
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

      it 'fails the parent context' do
        result = parent.call(child: child, a_param: :foo)
        expect(result).to be_failure
        expect(result.errors).to include 'BOOM'
      end

      it 'invalidates the parent context' do
        result = parent.call(child: child)
        expect(result).to be_failure
        expect(result).to be_invalid
        expect(result.errors).to include 'Required parameters: a_param'
      end

      it 'allows organizers to run normally' do
        organizer.organize(simple)
        result = organizer.call(a_param: :foo)
        expect(result).to be_success
      end

      it 'allows organizers to fail normally' do
        organizer.organize(child)
        result = organizer.call(a_param: :foo)
        expect(result).to be_failure
        expect(result.errors).to eq ['BOOM']
      end

      it 'allows organizers to invalidate normally' do
        organizer.organize(child)
        result = organizer.call
        expect(result).to be_failure
        expect(result.errors).to include 'Required parameters: a_param'
      end
    end
  end
end
