<div name="button-dib" class="inline">
    <?php
    if (isset($_POST['polyscript-rescramble'])) {
        check_admin_referer('polyscript-admin');
        Polyscript::shift_state('scrambling'); ?>
        <div>Scrambling...</div>
        <?php
    }
    if (isset($_POST['polyscript-disable'])) {
        check_admin_referer('polyscript-admin');
        Polyscript::shift_state('disabling');
        ?>
        <div>Scrambling...</div>
    <?php }
    if ($state === 'on') { ?>
        <div id="status-label"><strong>&#10004 Polyscripting Enabled</strong></div><?php
    } else if ($state === 'off') { ?>
        <div class="centered" id="status-label"><strong>&#10007 Polyscripting Disabled</strong></div><?php
    } else if ($state === 'disabling') { ?>
        <div id="status" class="loader"></div>
        <div>Disabling Polyscripting...</div>
    <?php } else if ($state === 'scrambling') { ?>
        <div id="status" class="loader"></div>
        <div>Scrambling...</div>
    <?php } ?>
    <div><?php echo "DEBUG HELP:" . $state; ?></div>
    <form action="" method="post" id="polyscript-settings">
        <?php wp_nonce_field('polyscript-admin');
        if ($state === 'on') { ?>
            <button class="submit" title="Generate new PHP syntax.">
                <input class="ps-button ps-rescramble"
                       type="submit"
                       name="polyscript-rescramble"
                       id="rescramble"
                       value="<?php _e('Rescramble', 'polyscript-settings'); ?>">
            </button>
            <button class="submit" title="Disable Polyscripting.">
                <input
                        class="ps-button ps-unscramble"
                        type="submit"
                        name="polyscript-disable"
                        id="unscramble"
                        value="<?php _e('Unscramble', 'polyscript-settings'); ?>">
            </button>
            <?php
        } else if ($state === 'off') { ?>
            <button disabled class="submit" title="Generating New Scramble.">
                <input
                        class="ps-button ps-rescramble"
                        type="submit"
                        name="polyscript-rescramble"
                        id="rescramble"
                        value="<?php _e('Scramble', 'polyscript-settings'); ?>">
            </button>
            <button disabled class="submit" title="Polyscripting not enabled.">
                <input disabled
                       class="ps-button ps-unscramble ps-disabled"
                       type="submit" name=""
                       id="unscramble"
                       value="<?php _e('Unscramble', 'polyscript-settings'); ?>">
            </button>
        <?php } ?>
    </form>
</div>