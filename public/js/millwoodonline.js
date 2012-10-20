$(document).ready(function() {
if ($('#tweets').length) {
  $.getJSON('https://api.twitter.com/1/statuses/user_timeline.json?callback=?&exclude_replies=true&include_entities=true&include_rts=false&screen_name=timmillwood', function(data) {
    $.each(data, function(key, value) {
	  if(key < 3) {
		  console.log(value);
        $('#tweets').append('<li><img src="' + value.user.profile_image_url + '" style="float: left; padding-right: 10px">' + replaceURLWithHTMLLinks(value.text) + '<hr></li>');
      }
    });
  });
}
});

function replaceURLWithHTMLLinks(text) {
    var exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig;
    return text.replace(exp,"<a href='$1'>$1</a>"); 
}
