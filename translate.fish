#!/usr/bin/env fish

# ==================================================
# CONFIGURATION
# ==================================================

set CONFIG_DIR ~/.config/translate
set CONFIG_FILE $CONFIG_DIR/config.fish

set DEFAULT_MODEL "kaelri/hy-mt2:1.8b"
set DEFAULT_MODE "id->en"

mkdir -p $CONFIG_DIR

# ==================================================
# COLOR PALETTE
# ==================================================

set c_mode (set_color d33d2c)
set c_model (set_color a9ab25)
set c_reset (set_color d6c8a3)

# ==================================================
# GUM CONFIGURATION
# ==================================================

set -gx GUM_CHOOSE_HEADER_FOREGROUND "#d6c8a3"
set -gx GUM_CHOOSE_ITEM_FOREGROUND "#888888"
set -gx GUM_CHOOSE_CURSOR_FOREGROUND "#c23b2c"

set -gx GUM_INPUT_CURSOR_FOREGROUND "#FFFFFF"

# ==================================================
# LOAD CONFIG
# ==================================================

if test -f $CONFIG_FILE
	source $CONFIG_FILE
end

if not set -q MODEL
	set -g MODEL $DEFAULT_MODEL
end

if not set -q TRANSLATION_MODE
	set -g TRANSLATION_MODE $DEFAULT_MODE
end

# ==================================================
# SAVE CONFIG
# ==================================================

function save_config

	mkdir -p $CONFIG_DIR

	echo "set -g MODEL '$MODEL'" > $CONFIG_FILE
	echo "set -g TRANSLATION_MODE '$TRANSLATION_MODE'" >> $CONFIG_FILE

end

# ==================================================
# MODEL SELECTION
# ==================================================

function choose_model

	set models (ollama list | tail -n +2 | awk '{print $1}')

	if test (count $models) -eq 0
		echo "No Ollama models found."
		return 1
	end

	set selected_model (printf "%s\n" $models | gum choose)

	if test -z "$selected_model"
		set selected_model "kaelri/hy-mt2:1.8b"
	end

	set -g MODEL "$selected_model"

	save_config

end

# ==================================================
# LANGUAGE SELECTION
# ==================================================

function choose_language

	set selected_mode (gum choose \
		"id->en" \
		"en->id" 
	)
	
	if test -z "$selected_mode"
		set selected_mode "en->id"
	end

	set -g TRANSLATION_MODE "$selected_mode"

	save_config

end

# ==================================================
# TOGGLE
# ==================================================

function toggle_language

	switch "$TRANSLATION_MODE"

		case "id->en"
			set -g TRANSLATION_MODE "en->id"

		case "en->id"
			set -g TRANSLATION_MODE "id->en"

		case "*"
			set -g TRANSLATION_MODE "en->id"

	end

	save_config

end

# ==================================================
# ARGUMENTS
# ==================================================

set choose_model_flag 0
set choose_language_flag 0

for arg in $argv

	switch $arg

		case "--choose-model" "-cm" "-m"
			set choose_model_flag 1

		case "--choose-language" "-cl" "-l"
			set choose_language_flag 1

	end

end

# ==================================================
# STARTUP MENUS
# ==================================================

if test $choose_model_flag -eq 1
	choose_model
end

if test $choose_language_flag -eq 1
	choose_language
end

# ==================================================
# BUILD PROMPT
# ==================================================


function build_prompt --argument-names mode text

	switch "$mode"

		case "id->en"
			set target_lang "English"

		case "en->id"
			set target_lang "Indonesia"

		case '*'
			set target_lang "English"

	end

	printf "%s" "
Translate the following text into $target_lang. Note that you should only output the translated result without any additional explanation:

$text
"

end

# ==================================================
# STATUS
# ==================================================

function get_status

	echo "Model : $c_model$MODEL$c_reset"
	echo "Mode  : $c_mode$TRANSLATION_MODE$c_reset"
	echo
end

# ==================================================
# HEADER
# ==================================================

echo "$c_reset"
echo "Translator Ready"

get_status

echo "Commands:"
echo "  /toggle"
echo "  /lang"
echo "  /model"
echo "  /status"
echo "  /bye"
echo

# ==================================================
# MAIN LOOP
# ==================================================

while true

	set text (gum input \
		--prompt "[$c_mode$TRANSLATION_MODE$c_reset][$c_model$MODEL$c_reset]> " \
		--placeholder "Type text to translate...")

	echo "[$c_mode$TRANSLATION_MODE$c_reset][$c_model$MODEL$c_reset]> $text"

	test -z "$text"
	and continue

	switch "$text"

		case "/bye"
			break

		case "/status"
			
			echo
			get_status
			continue

		case "/lang"
			
			choose_language

			echo
			echo "Mode changed to: $c_mode$TRANSLATION_MODE"
			echo

			continue

		case "/toggle"

			toggle_language

			echo
			echo "Mode changed to: $c_mode$TRANSLATION_MODE"
			echo

			continue

		case "/model"

			choose_model

			echo
			echo "Model changed to: $c_model$MODEL"
			echo

			continue

	end

	set prompt (build_prompt "$TRANSLATION_MODE" "$text")

	set_color white 

	echo 

	ollama run "$MODEL" "$prompt"

end

echo
echo "Goodbye!"
echo
