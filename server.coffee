polar = require 'polar'

app = polar port: 4337

app.get '/:path', (req, res, next) ->
    {path} = req.params
    if path.endsWith 'js'
        next()
    else
        res.end "<html><body><script src='#{path}.js'></script></body></html>"

app.start()
