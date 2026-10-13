# Local observability stack: Grafana + Loki + Alloy.
# Runs on localhost only — no network exposure. Starts/stops with the machine.
{
  config,
  pkgs,
  username,
  ...
}:
let
  lokiPort = 9831;
  grafanaPort = 9832;
  prometheusPort = 9090;
  nodeExporterPort = 9100;
  processExporterPort = 9256;
  hostname = config.networking.hostName;

  uid = toString config.users.users.${username}.uid;

  alloyConfigDir = pkgs.writeTextDir "config.alloy" ''
    loki.source.journal "system" {
      forward_to    = [loki.write.local.receiver]
      relabel_rules = loki.relabel.journal.rules
      max_age       = "12h"
      labels        = {
        job  = "systemd-journal",
        host = "${hostname}",
      }
    }

    loki.source.journal "user" {
      forward_to    = [loki.write.local.receiver]
      relabel_rules = loki.relabel.journal.rules
      max_age       = "12h"
      path          = "/var/log/journal"
      matches       = "_UID=${uid}"
      labels        = {
        job  = "user-journal",
        host = "${hostname}",
      }
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit", "__journal__systemd_user_unit"]
        separator     = ""
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
      rule {
        source_labels = ["__journal__transport"]
        target_label  = "transport"
      }
      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
      }
    }

    loki.write "local" {
      endpoint {
        url = "http://127.0.0.1:${toString lokiPort}/loki/api/v1/push"
      }
    }
  '';
in
{
  services = {
    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server.http_listen_port = lokiPort;
        server.log_level = "warn";

        common = {
          path_prefix = "/var/lib/loki";
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
          ring.instance_addr = "127.0.0.1";
        };

        memberlist = {
          bind_addr = [ "127.0.0.1" ];
          advertise_addr = "127.0.0.1";
          advertise_port = 7946;
        };

        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        storage_config.filesystem.directory = "/var/lib/loki/chunks";

        limits_config = {
          retention_period = "48h";
          allow_structured_metadata = false;
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          delete_request_store = "filesystem";
          retention_enabled = true;
        };
      };
    };

    alloy = {
      enable = true;
      configPath = alloyConfigDir;
    };

    prometheus = {
      enable = true;
      port = prometheusPort;
      listenAddress = "127.0.0.1";
      retentionTime = "48h";
      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            { targets = [ "127.0.0.1:${toString nodeExporterPort}" ]; }
          ];
        }
        {
          job_name = "process";
          static_configs = [
            { targets = [ "127.0.0.1:${toString processExporterPort}" ]; }
          ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          port = nodeExporterPort;
          listenAddress = "127.0.0.1";
        };
        process = {
          enable = true;
          port = processExporterPort;
          listenAddress = "127.0.0.1";
          settings.process_names = [
            {
              name = "{{.Comm}}";
              cmdline = [ ".+" ];
            }
          ];
        };
      };
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = grafanaPort;
        };
        analytics.reporting_enabled = false;
        log.level = "warn";
        security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
        "auth.anonymous" = {
          enabled = true;
          org_role = "Admin";
        };
        auth.disable_login_form = true;
      };

      provision = {
        datasources.settings.datasources = [
          {
            name = "Loki";
            type = "loki";
            uid = "loki";
            access = "proxy";
            url = "http://127.0.0.1:${toString lokiPort}";
            isDefault = true;
          }
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString prometheusPort}";
          }
        ];

        dashboards.settings.providers = [
          {
            name = "NixOS";
            options.path = "/etc/grafana/dashboards";
            options.foldersFromFilesStructure = true;
          }
        ];
      };
    };
  };

  environment.etc =
    let
      loki = {
        type = "loki";
        uid = "loki";
      };
      prom = {
        type = "prometheus";
        uid = "prometheus";
      };
      errFilter = ''level=~"emerg|alert|crit|err|error"'';

      # All dashboard UIDs/titles for cross-linking
      dashboardLinks = [
        {
          title = "Overview (all sources)";
          uid = "system-errors";
        }
        {
          title = "Systemd (failed units)";
          uid = "stream-systemd";
        }
        {
          title = "Hyprland (uwsm)";
          uid = "stream-hyprland";
        }
        {
          title = "Audio (pipewire)";
          uid = "stream-audio";
        }
        {
          title = "Bluetooth (bluetoothd)";
          uid = "stream-bluetooth";
        }
        {
          title = "Network (NetworkManager)";
          uid = "stream-network";
        }
        {
          title = "VPN (openvpn)";
          uid = "stream-vpn";
        }
        {
          title = "Docker (dockerd)";
          uid = "stream-docker";
        }
        {
          title = "Power (systemd-sleep)";
          uid = "stream-power";
        }
        {
          title = "Nix (nix-daemon)";
          uid = "stream-nix";
        }
        {
          title = "Kernel (dmesg)";
          uid = "stream-kernel";
        }
        {
          title = "Session (greetd)";
          uid = "stream-session";
        }
        {
          title = "System Resources";
          uid = "system-resources";
        }
      ];

      mkLinks =
        selfUid:
        map (d: {
          inherit (d) title;
          type = "link";
          url = "/d/${d.uid}";
          keepTime = true;
        }) (builtins.filter (d: d.uid != selfUid) dashboardLinks);

      # Helper: build a log stream dashboard
      # `labels` is the label filter WITHOUT braces, e.g. `host="foo", unit=~"bar.*"`
      mkStreamDashboard =
        {
          uid,
          title,
          description,
          labels,
          errQuery ? null,
          extraPanels ? [ ],
        }:
        let
          selector = "{${labels}}";
          errSelector = if errQuery != null then errQuery else "{${labels}, ${errFilter}}";
        in
        builtins.toJSON {
          annotations.list = [ ];
          inherit description;
          editable = true;
          graphTooltip = 1;
          links = mkLinks uid;
          refresh = "30s";
          panels = [
            {
              title = "Log Volume";
              type = "timeseries";
              gridPos = {
                h = 6;
                w = 16;
                x = 0;
                y = 0;
              };
              datasource = loki;
              targets = [
                {
                  expr = "sum(rate(${selector} [5m]))";
                  legendFormat = "logs/s";
                  refId = "A";
                }
              ];
              fieldConfig.defaults = {
                color.mode = "fixed";
                color.fixedColor = "blue";
                custom = {
                  drawStyle = "bars";
                  fillOpacity = 60;
                  lineWidth = 0;
                  pointSize = 5;
                };
                unit = "short";
              };
            }
            {
              title = "Total Logs";
              type = "stat";
              gridPos = {
                h = 3;
                w = 4;
                x = 16;
                y = 0;
              };
              datasource = loki;
              targets = [
                {
                  expr = "sum(count_over_time(${selector} [$__range]))";
                  refId = "A";
                }
              ];
              fieldConfig.defaults = {
                thresholds.steps = [
                  {
                    color = "blue";
                    value = null;
                  }
                ];
                noValue = "0";
              };
              options = {
                colorMode = "background_solid";
                graphMode = "none";
                textMode = "value";
                reduceOptions.calcs = [ "lastNotNull" ];
              };
            }
            {
              title = "Errors";
              type = "stat";
              gridPos = {
                h = 3;
                w = 4;
                x = 20;
                y = 0;
              };
              datasource = loki;
              targets = [
                {
                  expr = "sum(count_over_time(${errSelector} [$__range]))";
                  refId = "A";
                }
              ];
              fieldConfig.defaults = {
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "yellow";
                      value = 1;
                    }
                    {
                      color = "red";
                      value = 10;
                    }
                  ];
                };
                noValue = "0";
              };
              options = {
                colorMode = "background_solid";
                graphMode = "none";
                textMode = "value";
                reduceOptions.calcs = [ "lastNotNull" ];
              };
            }
          ]
          ++ [
            {
              title = "Log Levels";
              description = "Breakdown of log entries by priority level";
              type = "piechart";
              gridPos = {
                h = 6;
                w = 8;
                x = 16;
                y = 3;
              };
              datasource = loki;
              targets = [
                {
                  expr = "sum(count_over_time(${selector} [$__range])) by (level)";
                  legendFormat = "{{level}}";
                  refId = "A";
                }
              ];
              fieldConfig.defaults = { };
              fieldConfig.overrides = [
                {
                  matcher = {
                    id = "byName";
                    options = "error";
                  };
                  properties = [
                    {
                      id = "color";
                      value = {
                        mode = "fixed";
                        fixedColor = "red";
                      };
                    }
                  ];
                }
                {
                  matcher = {
                    id = "byName";
                    options = "crit";
                  };
                  properties = [
                    {
                      id = "color";
                      value = {
                        mode = "fixed";
                        fixedColor = "dark-red";
                      };
                    }
                  ];
                }
                {
                  matcher = {
                    id = "byName";
                    options = "warning";
                  };
                  properties = [
                    {
                      id = "color";
                      value = {
                        mode = "fixed";
                        fixedColor = "yellow";
                      };
                    }
                  ];
                }
                {
                  matcher = {
                    id = "byName";
                    options = "notice";
                  };
                  properties = [
                    {
                      id = "color";
                      value = {
                        mode = "fixed";
                        fixedColor = "blue";
                      };
                    }
                  ];
                }
                {
                  matcher = {
                    id = "byName";
                    options = "info";
                  };
                  properties = [
                    {
                      id = "color";
                      value = {
                        mode = "fixed";
                        fixedColor = "green";
                      };
                    }
                  ];
                }
                {
                  matcher = {
                    id = "byName";
                    options = "debug";
                  };
                  properties = [
                    {
                      id = "color";
                      value = {
                        mode = "fixed";
                        fixedColor = "purple";
                      };
                    }
                  ];
                }
              ];
              options = {
                legend = {
                  displayMode = "table";
                  placement = "right";
                  values = [
                    "value"
                    "percent"
                  ];
                };
                pieType = "donut";
                reduceOptions.calcs = [ "lastNotNull" ];
              };
            }
          ]
          ++ extraPanels
          ++ [
            {
              title = "All Logs";
              type = "logs";
              gridPos = {
                h = 16;
                w = 24;
                x = 0;
                y = 9;
              };
              datasource = loki;
              targets = [
                {
                  expr = selector;
                  refId = "A";
                }
              ];
              options = {
                showTime = true;
                showLabels = true;
                showCommonLabels = false;
                sortOrder = "Descending";
                wrapLogMessage = true;
                enableLogDetails = true;
                dedupStrategy = "none";
              };
            }
          ];
          schemaVersion = 39;
          tags = [
            "nixos"
            "stream"
          ];
          templating.list = [ ];
          time = {
            from = "now-1h";
            to = "now";
          };
          inherit title uid;
        };

    in
    {

      "grafana/dashboards/system-errors.json".text = builtins.toJSON {
        annotations.list = [ ];
        description = "High-level overview of all monitored log sources";
        editable = true;
        graphTooltip = 1;
        links = mkLinks "system-errors";
        refresh = "30s";
        panels = [

          # -- Top stat row --
          {
            title = "Total Errors";
            description = "Error-level log lines across all sources";
            type = "stat";
            gridPos = {
              h = 4;
              w = 12;
              x = 0;
              y = 8;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", ${errFilter}} [$__range]))'';
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 10;
                  }
                  {
                    color = "red";
                    value = 100;
                  }
                ];
              };
              noValue = "0";
            };
            options = {
              colorMode = "background_solid";
              graphMode = "area";
              textMode = "value";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
          {
            title = "Total Warnings";
            description = "Warning-level log lines across all sources";
            type = "stat";
            gridPos = {
              h = 4;
              w = 12;
              x = 12;
              y = 8;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", level="warning"} [$__range]))'';
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 50;
                  }
                  {
                    color = "orange";
                    value = 200;
                  }
                ];
              };
              noValue = "0";
            };
            options = {
              colorMode = "background_solid";
              graphMode = "area";
              textMode = "value";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }

          # -- Pie charts: log volume by source --
          {
            title = "Log Volume by Source";
            description = "Total log lines from each monitored source";
            type = "piechart";
            gridPos = {
              h = 12;
              w = 8;
              x = 0;
              y = 12;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia"} [$__range]))'';
                legendFormat = "Hyprland (uwsm)";
                refId = "A";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"pipewire.*|wireplumber.*"} [$__range]))'';
                legendFormat = "Audio (pipewire)";
                refId = "B";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"bluetoothd|bluez"} [$__range]))'';
                legendFormat = "Bluetooth (bluetoothd)";
                refId = "C";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"NetworkManager|systemd-resolved|wpa_supplicant"} [$__range]))'';
                legendFormat = "Network (NetworkManager)";
                refId = "D";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"openvpn.*"} [$__range]))'';
                legendFormat = "VPN (openvpn)";
                refId = "E";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"docker.*"} [$__range]))'';
                legendFormat = "Docker (dockerd)";
                refId = "F";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"systemd-sleep|systemd-logind|power-profiles-daemon"} [$__range]))'';
                legendFormat = "Power (systemd-sleep)";
                refId = "G";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"nix-daemon.*"} [$__range]))'';
                legendFormat = "Nix (nix-daemon)";
                refId = "H";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", transport="kernel"} [$__range]))'';
                legendFormat = "Kernel (dmesg)";
                refId = "I";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"uwsm|greetd|systemd-logind"} [$__range]))'';
                legendFormat = "Session (greetd)";
                refId = "J";
              }
            ];
            options = {
              legend = {
                displayMode = "table";
                placement = "right";
                values = [
                  "value"
                  "percent"
                ];
              };
              pieType = "donut";
              reduceOptions.calcs = [ "lastNotNull" ];
              tooltip.mode = "single";
            };
          }

          # -- Errors by source pie chart --
          {
            title = "Errors by Source";
            description = "Error-level log lines from each monitored source";
            type = "piechart";
            gridPos = {
              h = 12;
              w = 8;
              x = 8;
              y = 12;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia", ${errFilter}} [$__range]))'';
                legendFormat = "Hyprland (uwsm)";
                refId = "A";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"pipewire.*|wireplumber.*", ${errFilter}} [$__range]))'';
                legendFormat = "Audio (pipewire)";
                refId = "B";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"bluetoothd|bluez", ${errFilter}} [$__range]))'';
                legendFormat = "Bluetooth (bluetoothd)";
                refId = "C";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"NetworkManager|systemd-resolved|wpa_supplicant", ${errFilter}} [$__range]))'';
                legendFormat = "Network (NetworkManager)";
                refId = "D";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"openvpn.*", ${errFilter}} [$__range]))'';
                legendFormat = "VPN (openvpn)";
                refId = "E";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"docker.*", ${errFilter}} [$__range]))'';
                legendFormat = "Docker (dockerd)";
                refId = "F";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"systemd-sleep|systemd-logind|power-profiles-daemon", ${errFilter}} [$__range]))'';
                legendFormat = "Power (systemd-sleep)";
                refId = "G";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"nix-daemon.*", ${errFilter}} [$__range]))'';
                legendFormat = "Nix (nix-daemon)";
                refId = "H";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", transport="kernel", ${errFilter}} [$__range]))'';
                legendFormat = "Kernel (dmesg)";
                refId = "I";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"uwsm|greetd|systemd-logind", ${errFilter}} [$__range]))'';
                legendFormat = "Session (greetd)";
                refId = "J";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", ${errFilter}, syslog_identifier!~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia|bluetoothd|bluez|NetworkManager|systemd-resolved|wpa_supplicant|systemd-sleep|systemd-logind|power-profiles-daemon|uwsm|greetd", unit!~"pipewire.*|wireplumber.*|openvpn.*|docker.*|nix-daemon.*", transport!="kernel"} [$__range]))'';
                legendFormat = "Other";
                refId = "K";
              }
            ];
            options = {
              legend = {
                displayMode = "table";
                placement = "right";
                values = [
                  "value"
                  "percent"
                ];
              };
              pieType = "donut";
              reduceOptions.calcs = [ "lastNotNull" ];
              tooltip.mode = "single";
            };
          }

          # -- Warnings by source pie chart --
          {
            title = "Warnings by Source";
            description = "Warning-level log lines from each monitored source";
            type = "piechart";
            gridPos = {
              h = 12;
              w = 8;
              x = 16;
              y = 12;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia", level="warning"} [$__range]))'';
                legendFormat = "Hyprland (uwsm)";
                refId = "A";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"pipewire.*|wireplumber.*", level="warning"} [$__range]))'';
                legendFormat = "Audio (pipewire)";
                refId = "B";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"bluetoothd|bluez", level="warning"} [$__range]))'';
                legendFormat = "Bluetooth (bluetoothd)";
                refId = "C";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"NetworkManager|systemd-resolved|wpa_supplicant", level="warning"} [$__range]))'';
                legendFormat = "Network (NetworkManager)";
                refId = "D";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"openvpn.*", level="warning"} [$__range]))'';
                legendFormat = "VPN (openvpn)";
                refId = "E";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"docker.*", level="warning"} [$__range]))'';
                legendFormat = "Docker (dockerd)";
                refId = "F";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"systemd-sleep|systemd-logind|power-profiles-daemon", level="warning"} [$__range]))'';
                legendFormat = "Power (systemd-sleep)";
                refId = "G";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~"nix-daemon.*", level="warning"} [$__range]))'';
                legendFormat = "Nix (nix-daemon)";
                refId = "H";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", transport="kernel", level="warning"} [$__range]))'';
                legendFormat = "Kernel (dmesg)";
                refId = "I";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", syslog_identifier=~"uwsm|greetd|systemd-logind", level="warning"} [$__range]))'';
                legendFormat = "Session (greetd)";
                refId = "J";
              }
              {
                expr = ''sum(count_over_time({host="${hostname}", level="warning", syslog_identifier!~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia|bluetoothd|bluez|NetworkManager|systemd-resolved|wpa_supplicant|systemd-sleep|systemd-logind|power-profiles-daemon|uwsm|greetd", unit!~"pipewire.*|wireplumber.*|openvpn.*|docker.*|nix-daemon.*", transport!="kernel"} [$__range]))'';
                legendFormat = "Other";
                refId = "K";
              }
            ];
            options = {
              legend = {
                displayMode = "table";
                placement = "right";
                values = [
                  "value"
                  "percent"
                ];
              };
              pieType = "donut";
              reduceOptions.calcs = [ "lastNotNull" ];
              tooltip.mode = "single";
            };
          }

          # -- Error timeline --
          {
            title = "Error Timeline";
            description = "Error rate over time by source";
            type = "timeseries";
            gridPos = {
              h = 8;
              w = 24;
              x = 0;
              y = 0;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(rate({host="${hostname}", ${errFilter}} [5m])) by (unit)'';
                legendFormat = "{{unit}}";
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "palette-classic";
              custom = {
                drawStyle = "bars";
                fillOpacity = 80;
                stacking.mode = "normal";
                pointSize = 5;
                lineWidth = 0;
              };
              unit = "short";
            };
            options.legend = {
              displayMode = "list";
              placement = "bottom";
            };
          }
        ];
        schemaVersion = 39;
        tags = [
          "nixos"
          "overview"
        ];
        templating.list = [ ];
        time = {
          from = "now-3h";
          to = "now";
        };
        title = "Overview (all sources)";
        uid = "system-errors";
      };

      "grafana/dashboards/system-resources.json".text = builtins.toJSON {
        annotations.list = [ ];
        description = "CPU, memory, disk, and swap with per-process breakdowns";
        editable = true;
        graphTooltip = 1;
        links = mkLinks "system-resources";
        refresh = "30s";
        panels = [
          {
            title = "CPU";
            type = "gauge";
            gridPos = {
              h = 5;
              w = 6;
              x = 0;
              y = 0;
            };
            datasource = prom;
            targets = [
              {
                expr = ''100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'';
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              unit = "percent";
              min = 0;
              max = 100;
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 70;
                  }
                  {
                    color = "red";
                    value = 90;
                  }
                ];
              };
            };
            options.reduceOptions.calcs = [ "lastNotNull" ];
          }
          {
            title = "Memory";
            type = "gauge";
            gridPos = {
              h = 5;
              w = 6;
              x = 6;
              y = 0;
            };
            datasource = prom;
            targets = [
              {
                expr = "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100";
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              unit = "percent";
              min = 0;
              max = 100;
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 70;
                  }
                  {
                    color = "red";
                    value = 90;
                  }
                ];
              };
            };
            options.reduceOptions.calcs = [ "lastNotNull" ];
          }
          {
            title = "Disk (/)";
            type = "gauge";
            gridPos = {
              h = 5;
              w = 6;
              x = 12;
              y = 0;
            };
            datasource = prom;
            targets = [
              {
                expr = ''(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100'';
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              unit = "percent";
              min = 0;
              max = 100;
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 70;
                  }
                  {
                    color = "red";
                    value = 90;
                  }
                ];
              };
            };
            options.reduceOptions.calcs = [ "lastNotNull" ];
          }
          {
            title = "Swap";
            type = "gauge";
            gridPos = {
              h = 5;
              w = 6;
              x = 18;
              y = 0;
            };
            datasource = prom;
            targets = [
              {
                expr = "(1 - node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes) * 100";
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              unit = "percent";
              min = 0;
              max = 100;
              noValue = "N/A";
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 50;
                  }
                  {
                    color = "red";
                    value = 80;
                  }
                ];
              };
            };
            options.reduceOptions.calcs = [ "lastNotNull" ];
          }

          {
            title = "CPU";
            type = "stat";
            gridPos = {
              h = 3;
              w = 6;
              x = 0;
              y = 5;
            };
            datasource = prom;
            targets = [
              {
                expr = ''sum(irate(node_cpu_seconds_total{mode!="idle"}[5m]))'';
                legendFormat = "Active";
                instant = true;
                refId = "A";
              }
              {
                expr = ''count(count(node_cpu_seconds_total{mode="idle"}) by (cpu))'';
                legendFormat = "Total";
                instant = true;
                refId = "B";
              }
            ];
            fieldConfig.defaults = {
              unit = "short";
              decimals = 1;
              thresholds.steps = [
                {
                  color = "text";
                  value = null;
                }
              ];
            };
            options = {
              colorMode = "none";
              graphMode = "none";
              textMode = "value_and_name";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
          {
            title = "Memory";
            type = "stat";
            gridPos = {
              h = 3;
              w = 6;
              x = 6;
              y = 5;
            };
            datasource = prom;
            targets = [
              {
                expr = "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes";
                legendFormat = "Used";
                instant = true;
                refId = "A";
              }
              {
                expr = "node_memory_MemTotal_bytes";
                legendFormat = "Total";
                instant = true;
                refId = "B";
              }
            ];
            fieldConfig.defaults = {
              unit = "bytes";
              thresholds.steps = [
                {
                  color = "text";
                  value = null;
                }
              ];
            };
            options = {
              colorMode = "none";
              graphMode = "none";
              textMode = "value_and_name";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
          {
            title = "Disk (/)";
            type = "stat";
            gridPos = {
              h = 3;
              w = 6;
              x = 12;
              y = 5;
            };
            datasource = prom;
            targets = [
              {
                expr = ''node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"}'';
                legendFormat = "Used";
                instant = true;
                refId = "A";
              }
              {
                expr = ''node_filesystem_size_bytes{mountpoint="/"}'';
                legendFormat = "Total";
                instant = true;
                refId = "B";
              }
            ];
            fieldConfig.defaults = {
              unit = "bytes";
              thresholds.steps = [
                {
                  color = "text";
                  value = null;
                }
              ];
            };
            options = {
              colorMode = "none";
              graphMode = "none";
              textMode = "value_and_name";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
          {
            title = "Swap";
            type = "stat";
            gridPos = {
              h = 3;
              w = 6;
              x = 18;
              y = 5;
            };
            datasource = prom;
            targets = [
              {
                expr = "node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes";
                legendFormat = "Used";
                instant = true;
                refId = "A";
              }
              {
                expr = "node_memory_SwapTotal_bytes";
                legendFormat = "Total";
                instant = true;
                refId = "B";
              }
            ];
            fieldConfig.defaults = {
              unit = "bytes";
              noValue = "N/A";
              thresholds.steps = [
                {
                  color = "text";
                  value = null;
                }
              ];
            };
            options = {
              colorMode = "none";
              graphMode = "none";
              textMode = "value_and_name";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }

          {
            title = "CPU Usage Over Time";
            type = "timeseries";
            gridPos = {
              h = 8;
              w = 15;
              x = 0;
              y = 8;
            };
            datasource = prom;
            targets = [
              {
                expr = ''avg(irate(node_cpu_seconds_total{mode!="idle"}[5m])) by (mode) * 100'';
                legendFormat = "{{mode}}";
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "palette-classic";
              custom = {
                drawStyle = "line";
                fillOpacity = 60;
                stacking.mode = "normal";
                lineWidth = 1;
                pointSize = 5;
              };
              unit = "percent";
            };
            options.legend = {
              displayMode = "list";
              placement = "bottom";
            };
          }
          {
            title = "Top Processes by CPU";
            type = "bargauge";
            gridPos = {
              h = 8;
              w = 9;
              x = 15;
              y = 8;
            };
            datasource = prom;
            targets = [
              {
                expr = "topk(10, sum(rate(namedprocess_namegroup_cpu_seconds_total[5m])) by (groupname))";
                legendFormat = "{{groupname}}";
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "continuous-GrYlRd";
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "percentunit";
            };
            options = {
              orientation = "horizontal";
              displayMode = "gradient";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }

          {
            title = "Memory Usage Over Time";
            type = "timeseries";
            gridPos = {
              h = 8;
              w = 15;
              x = 0;
              y = 16;
            };
            datasource = prom;
            targets = [
              {
                expr = "node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - node_memory_Cached_bytes";
                legendFormat = "Used";
                refId = "A";
              }
              {
                expr = "node_memory_Buffers_bytes";
                legendFormat = "Buffers";
                refId = "B";
              }
              {
                expr = "node_memory_Cached_bytes";
                legendFormat = "Cached";
                refId = "C";
              }
              {
                expr = "node_memory_MemFree_bytes";
                legendFormat = "Free";
                refId = "D";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "palette-classic";
              custom = {
                drawStyle = "line";
                fillOpacity = 60;
                stacking.mode = "normal";
                lineWidth = 1;
                pointSize = 5;
              };
              unit = "bytes";
            };
            fieldConfig.overrides = [
              {
                matcher = {
                  id = "byName";
                  options = "Used";
                };
                properties = [
                  {
                    id = "color";
                    value = {
                      mode = "fixed";
                      fixedColor = "red";
                    };
                  }
                ];
              }
              {
                matcher = {
                  id = "byName";
                  options = "Buffers";
                };
                properties = [
                  {
                    id = "color";
                    value = {
                      mode = "fixed";
                      fixedColor = "orange";
                    };
                  }
                ];
              }
              {
                matcher = {
                  id = "byName";
                  options = "Cached";
                };
                properties = [
                  {
                    id = "color";
                    value = {
                      mode = "fixed";
                      fixedColor = "yellow";
                    };
                  }
                ];
              }
              {
                matcher = {
                  id = "byName";
                  options = "Free";
                };
                properties = [
                  {
                    id = "color";
                    value = {
                      mode = "fixed";
                      fixedColor = "green";
                    };
                  }
                ];
              }
            ];
            options.legend = {
              displayMode = "list";
              placement = "bottom";
            };
          }
          {
            title = "Top Processes by Memory";
            type = "bargauge";
            gridPos = {
              h = 8;
              w = 9;
              x = 15;
              y = 16;
            };
            datasource = prom;
            targets = [
              {
                expr = ''topk(10, sum(namedprocess_namegroup_memory_bytes{memtype="resident"}) by (groupname))'';
                legendFormat = "{{groupname}}";
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "continuous-GrYlRd";
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "bytes";
            };
            options = {
              orientation = "horizontal";
              displayMode = "gradient";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }

          {
            title = "Filesystem Usage";
            type = "bargauge";
            gridPos = {
              h = 8;
              w = 15;
              x = 0;
              y = 24;
            };
            datasource = prom;
            targets = [
              {
                expr = ''(1 - node_filesystem_avail_bytes{fstype!~"tmpfs|devtmpfs|squashfs|overlay|efivarfs"} / node_filesystem_size_bytes{fstype!~"tmpfs|devtmpfs|squashfs|overlay|efivarfs"}) * 100'';
                legendFormat = "{{mountpoint}}";
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              unit = "percent";
              min = 0;
              max = 100;
              color.mode = "continuous-GrYlRd";
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
            };
            options = {
              orientation = "horizontal";
              displayMode = "gradient";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
          {
            title = "Top Processes by Disk I/O";
            type = "bargauge";
            gridPos = {
              h = 8;
              w = 9;
              x = 15;
              y = 24;
            };
            datasource = prom;
            targets = [
              {
                expr = "topk(10, sum(rate(namedprocess_namegroup_read_bytes_total[5m]) + rate(namedprocess_namegroup_write_bytes_total[5m])) by (groupname))";
                legendFormat = "{{groupname}}";
                instant = true;
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "continuous-GrYlRd";
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                ];
              };
              unit = "Bps";
            };
            options = {
              orientation = "horizontal";
              displayMode = "gradient";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
        ];
        schemaVersion = 39;
        tags = [
          "nixos"
          "resources"
        ];
        templating.list = [ ];
        time = {
          from = "now-1h";
          to = "now";
        };
        title = "System Resources";
        uid = "system-resources";
      };

      "grafana/dashboards/stream-hyprland.json".text = mkStreamDashboard {
        uid = "stream-hyprland";
        title = "Hyprland (uwsm)";
        description = "Hyprland compositor + Noctalia shell — everything under the UWSM desktop session";
        labels = ''host="${hostname}", syslog_identifier=~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia"'';
        errQuery = ''{host="${hostname}", syslog_identifier=~"Hyprland|hyprland|uwsm_hyprland.desktop|uwsm-app|noctalia|dev.noctalia.Noctalia"} |~ `(?i)(\\bERR\\b|error|fatal|panic|crash|critical)`'';
      };

      "grafana/dashboards/stream-audio.json".text = mkStreamDashboard {
        uid = "stream-audio";
        title = "Audio (pipewire)";
        description = "PipeWire and WirePlumber — device changes, profile switches, codec issues";
        labels = ''host="${hostname}", unit=~"pipewire.*|wireplumber.*"'';
      };

      "grafana/dashboards/stream-bluetooth.json".text = mkStreamDashboard {
        uid = "stream-bluetooth";
        title = "Bluetooth (bluetoothd)";
        description = "Pairing, connections, codec negotiation, disconnects";
        labels = ''host="${hostname}", syslog_identifier=~"bluetoothd|bluez"'';
      };

      "grafana/dashboards/stream-network.json".text = mkStreamDashboard {
        uid = "stream-network";
        title = "Network (NetworkManager)";
        description = "WiFi, DHCP, DNS, roaming, connection state";
        labels = ''host="${hostname}", syslog_identifier=~"NetworkManager|systemd-resolved|wpa_supplicant"'';
      };

      "grafana/dashboards/stream-vpn.json".text = mkStreamDashboard {
        uid = "stream-vpn";
        title = "VPN (openvpn)";
        description = "OpenVPN/ExpressVPN connections, auth, routing";
        labels = ''host="${hostname}", unit=~"openvpn.*"'';
      };

      "grafana/dashboards/stream-docker.json".text = mkStreamDashboard {
        uid = "stream-docker";
        title = "Docker (dockerd)";
        description = "Container lifecycle, daemon errors, image pulls";
        labels = ''host="${hostname}", unit=~"docker.*"'';
      };

      "grafana/dashboards/stream-power.json".text = mkStreamDashboard {
        uid = "stream-power";
        title = "Power (systemd-sleep)";
        description = "Suspend, resume, lid events, power profile changes";
        labels = ''host="${hostname}", syslog_identifier=~"systemd-sleep|systemd-logind|power-profiles-daemon"'';
      };

      "grafana/dashboards/stream-nix.json".text = mkStreamDashboard {
        uid = "stream-nix";
        title = "Nix (nix-daemon)";
        description = "Nix daemon — builds, substitutions, store operations";
        labels = ''host="${hostname}", unit=~"nix-daemon.*"'';
      };

      "grafana/dashboards/stream-kernel.json".text = mkStreamDashboard {
        uid = "stream-kernel";
        title = "Kernel (dmesg)";
        description = "dmesg equivalent — hardware, drivers, filesystems, thermals";
        labels = ''host="${hostname}", transport="kernel"'';
      };

      "grafana/dashboards/stream-session.json".text = mkStreamDashboard {
        uid = "stream-session";
        title = "Session (greetd)";
        description = "UWSM session manager, compositor handoff, login";
        labels = ''host="${hostname}", syslog_identifier=~"uwsm|greetd|systemd-logind"'';
      };

      "grafana/dashboards/stream-systemd.json".text = builtins.toJSON {
        annotations.list = [ ];
        description = "Systemd service failures — exit codes, core dumps, and failed units";
        editable = true;
        graphTooltip = 1;
        links = mkLinks "stream-systemd";
        refresh = "30s";
        panels = [

          # -- Top row --
          {
            title = "Failed Units";
            description = "Services that exited with failure, dumped core, or reported exit-code errors";
            type = "stat";
            gridPos = {
              h = 4;
              w = 8;
              x = 0;
              y = 0;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~".+\\.service", unit!~"(loki|grafana|alloy)\\.service"} |~ `(?i)(failed|exit-code|dumped core)` [$__range]))'';
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = null;
                  }
                  {
                    color = "yellow";
                    value = 1;
                  }
                  {
                    color = "red";
                    value = 10;
                  }
                ];
              };
              noValue = "0";
            };
            options = {
              colorMode = "background_solid";
              graphMode = "area";
              textMode = "value";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }
          {
            title = "Failure Timeline";
            description = "Service failure rate over time";
            type = "timeseries";
            gridPos = {
              h = 8;
              w = 16;
              x = 8;
              y = 0;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(rate({host="${hostname}", unit=~".+\\.service", unit!~"(loki|grafana|alloy)\\.service"} |~ `(?i)(failed|exit-code|dumped core)` [5m])) by (unit)'';
                legendFormat = "{{unit}}";
                refId = "A";
              }
            ];
            fieldConfig.defaults = {
              color.mode = "palette-classic";
              custom = {
                drawStyle = "bars";
                fillOpacity = 80;
                stacking.mode = "normal";
                pointSize = 5;
                lineWidth = 0;
              };
              unit = "short";
            };
            options.legend = {
              displayMode = "list";
              placement = "bottom";
            };
          }
          {
            title = "Failures by Unit";
            description = "Which services are failing the most";
            type = "piechart";
            gridPos = {
              h = 8;
              w = 8;
              x = 0;
              y = 4;
            };
            datasource = loki;
            targets = [
              {
                expr = ''sum(count_over_time({host="${hostname}", unit=~".+\\.service", unit!~"(loki|grafana|alloy)\\.service"} |~ `(?i)(failed|exit-code|dumped core)` [$__range])) by (unit)'';
                legendFormat = "{{unit}}";
                refId = "A";
              }
            ];
            options = {
              legend = {
                displayMode = "table";
                placement = "right";
                values = [
                  "value"
                  "percent"
                ];
              };
              pieType = "donut";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          }

          # -- Failure logs --
          {
            title = "Service Failure Logs";
            description = "All log lines indicating service failure";
            type = "logs";
            gridPos = {
              h = 16;
              w = 24;
              x = 0;
              y = 12;
            };
            datasource = loki;
            targets = [
              {
                expr = ''{host="${hostname}", unit=~".+\\.service", unit!~"(loki|grafana|alloy)\\.service"} |~ `(?i)(failed|exit-code|dumped core)`'';
                refId = "A";
              }
            ];
            options = {
              showTime = true;
              showLabels = true;
              showCommonLabels = false;
              sortOrder = "Descending";
              wrapLogMessage = true;
              enableLogDetails = true;
              dedupStrategy = "none";
            };
          }
        ];
        schemaVersion = 39;
        tags = [
          "nixos"
          "systemd"
        ];
        templating.list = [ ];
        time = {
          from = "now-3h";
          to = "now";
        };
        title = "Systemd (failed units)";
        uid = "stream-systemd";
      };

    }; # close environment.etc
}
