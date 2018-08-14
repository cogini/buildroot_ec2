################################################################################
#
# erlang-app
#
################################################################################

ERLANG_APP_VERSION = 0.1
ERLANG_APP_SITE = $(ERLANG_APP_PKGDIR).
ERLANG_APP_SITE_METHOD = local
ERLANG_APP_LICENSE = Apache-2.0

define ERLANG_APP_INSTALL_TARGET_CMDS
    $(INSTALL) -d -m 0755 $(TARGET_DIR)/srv/erlang-app
endef

define ERLANG_APP_INSTALL_INIT_SYSTEMD
    $(INSTALL) -D -m 644 $(ERLANG_APP_PKGDIR)/erlang-app.service \
        $(TARGET_DIR)/usr/lib/systemd/system/erlang-app.service
    mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants
    ln -fs ../../../../usr/lib/systemd/system/erlang-app.service \
        $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/erlang-app.service
endef

define ERLANG_APP_USERS
    deploy -1 deploy -1 * - - - Erlang app deploy
    erlang-app -1 erlang-app -1 * - - - Erlang app user
endef

define ERLANG_APP_PERMISSIONS
    /srv/erlang-app  d  750  deploy  erlang-app   -  -  -  -  -
endef

$(eval $(generic-package))
