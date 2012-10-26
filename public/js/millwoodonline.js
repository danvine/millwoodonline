$(document).ready(function() {
if ($('#tweets').length) {
  $.getJSON('https://api.twitter.com/1/statuses/user_timeline.json?callback=?&exclude_replies=true&include_entities=true&include_rts=false&screen_name=timmillwood', function(data) {
    $.each(data, function(key, value) {
	  if(key < 3) {
		  console.log(value);
        $('#tweets').append('<li><img src="' + value.user.profile_image_url + '" style="float: left; padding-right: 10px">' + value.text.linkify().atify().hashify() + '<hr></li>');
      }
    });
  });
}
});

     String.prototype.hashify = function() {
            return this.replace(/#([A-Za-z0-9\/\.]*)/g, function(m) {
                return '<a target="_new" href="http://twitter.com/search?q=' + m.replace('#','') + '">' + m + "</a>";
            });
        };

        String.prototype.linkify = function(){
            return this.replace(/[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_:%&\?\/.=]+/, function(m) {
                return m.link(m);
            });
        };

        String.prototype.atify = function() {
            return this.replace(/@[\w]+/g, function(m) {
                return '<a href="http://www.twitter.com/' + m.replace('@','') + '">' + m + "</a>";
            });
        };
