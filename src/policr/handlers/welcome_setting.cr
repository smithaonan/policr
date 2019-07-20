module Policr
  class WelcomeSettingHandler < Handler
    allow_edit # 处理编辑消息

    target :fields

    def match(msg)
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
          (@reply_msg_id = _reply_msg_id),
          Cache.welcome_setting_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置欢迎消息指令？
        ]
      end
    end

    def handle(msg)
      if (group_id = @group_id) && (reply_msg_id = @reply_msg_id)
        chat_id = msg.chat.id

        KVStore.set_welcome(group_id, msg.text)

        updated_text, updated_markup = updated_settings_preview(group_id)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: reply_msg_id,
          text: updated_text,
          reply_markup: updated_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def updated_settings_preview(group_id)
      midcall WelcomeCommander do
        {_commander.text(group_id), _commander.markup(group_id)}
      end || {nil, nil}
    end
  end
end
