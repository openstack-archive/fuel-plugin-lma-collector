// Sample configuration for the LMA dashboard
// Copy this file to your Grafana source directory
define(['settings'], function(Settings) {

  return new Settings({
      datasources: {
        influxdb: {
          type: 'influxdb',
          url: "http://" + window.location.hostname + ":8086/db/lma",
          username: 'lma',
          password: 'lmapass',
        },
        grafana: {
          type: 'influxdb',
          url: "http://" + window.location.hostname + ":8086/db/grafana",
          username: 'lma',
          password: 'lmapass',
          grafanaDB: true
        },
      },

      search: {
        max_results: 100
      },

      default_route: '/dashboard/file/default.json',

      unsaved_changes_warning: true,

      playlist_timespan: "1m",

      admin: {
        password: ''
      },

      window_title_prefix: 'LMA - ',

      plugins: {
        panels: [],
        dependencies: [],
      }

    });
});
