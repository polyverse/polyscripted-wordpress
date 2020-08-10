<style>

    .alert {
        padding: 20px;
        background-color: #f49f0a;
        color: white;
    }
</style>

<?php
    if (isset($_POST['clear'])) {
        Polystate::clear_warning(); ?>
        <script>window.location.reload()</script>
    <?php
} ?>


<div class="alert">
    <form action="" method="post" id="polyscript-settings">
        <strong>Critical Error - </strong> Previous state shift failed. Check dispatcher logs.
        <input class="ps-button" type="submit" name="clear"
               value="<?php _e('clear', 'polyscript-settings'); ?>">
    </form>
</div>