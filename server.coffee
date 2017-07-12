polar = require 'polar'

app = polar port: 4337, metaserve:
    compilers:
        js: require 'metaserve-js-litcoffee-reactify'
        css: require 'metaserve-css-postcss'

app.get '/:path', (req, res, next) ->
    {path} = req.params
    if path.endsWith('.js') or path.endsWith('.css')
        next()
    else
        res.end """
        <html>
            <head><link rel='stylesheet' href='app.css' /></head>
            <body><script src='#{path}.js'></script></body>
        </html>
        """

app.start()
