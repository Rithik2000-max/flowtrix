Meteor.startup(() => {
  const defaults = {
    title: 'Flowtrix',
    'meta[name=description]': {
      name: 'description',
      content: 'Flowtrix is an open-source and collaborative Trello-like kanban board application.',
    },
  };

  DocHead.setDefaults(defaults);
});