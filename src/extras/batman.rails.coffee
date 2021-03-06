applyExtra = (Batman) ->
  Batman.mixin Batman.Encoders,
    railsDate:
      encode: (value) -> value
      decode: (value) ->
        a = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value)
        if a
          return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4], +a[5], +a[6]))
        else
          Batman.developer.warn "Unrecognized rails date #{value}!"
          return Date.parse(value)

  class Batman.RailsStorage extends Batman.RestStorage

    _addJsonExtension: (url) -> url + '.json'

    urlForRecord: -> @_addJsonExtension(super)
    urlForCollection: -> @_addJsonExtension(super)

    _errorsFrom422Response: (response) -> JSON.parse(response)

    @::after 'update', 'create', ({error, record, response}, next) ->
      if error
        # Rails validation errors
        if error.request?.get('status') == 422
          try
            validationErrors = @_errorsFrom422Response(response)
          catch extractionError
            return next(extractionError)

          for key, errorsArray of validationErrors
            for validationError in errorsArray
              record.get('errors').add(key, "#{key} #{validationError}")

          env = arguments[0]
          env.result = record
          env.error = record.get('errors')
          return next()
      next()

if (module? && require?)
  module.exports = applyExtra
else
  applyExtra(Batman)
