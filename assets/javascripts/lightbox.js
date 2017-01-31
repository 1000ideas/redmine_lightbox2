$(document).ready(function() {
  // modify thumbnail links and add filename to url to support fancybox preview
  $("div.wiki a.thumbnail").attr('href', function(i, v){
    return v + '/' + $(this).attr('title');
  });

  $("div.attachments a.lightbox," +
      "div.attachments a.lightbox_preview," +
    "div.journal ul.details a[href$='.png']," +
    "div.journal ul.details a[href$='.PNG']," +
    "div.journal ul.details a[href$='.jpg']," +
    "div.journal ul.details a[href$='.JPG']," +
    "div.journal ul.details a[href$='.jpeg']," +
    "div.journal ul.details a[href$='.JPEG']," +
    "div.journal ul.details a[href$='.gif']," +
    "div.journal ul.details a[href$='.GIF']," +
    "div.wiki a.thumbnail," +
    "div.attachments a.swf").fancybox({
      prevEffect    : 'none',
      nextEffect    : 'none',
      openSpeed   : 400,
      closeSpeed    : 200
    });

  $("div.attachments a.pdf").fancybox({
    prevEffect    : 'none',
    nextEffect    : 'none',
    openSpeed   : 400,
    closeSpeed    : 200,
    width     : '90%',
    height      : '90%',
    autoSize    : true,
    iframe : {
      preload: false
    }
  });

  $("div.attachments a.delete").each(function(idx, el) {
    $(el).bind('ajax:success', function(evt, data, status, xhr) {
      $(this).closest('p').hide();
    })
  })
});
