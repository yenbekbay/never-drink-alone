express = require('express');
app = express();

app.set('views', 'cloud/views');
app.set('view engine', 'ejs');
app.use(express.bodyParser());

app.get('/admin', function(req, res) {
  res.render('admin');
});

app.listen();
