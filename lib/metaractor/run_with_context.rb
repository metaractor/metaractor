module Metaractor
  module RunWithContext
    # Grab context at run and set things up.
    def run(context = {})
      _build_context context
      super()
    end

    def run!(context = {})
      _build_context context
      super()
    end

    def _build_context(context = {})
      @context = Interactor::Context.build(context) unless context.empty?
    end
  end
end
