<?php
define('CLI_SCRIPT', true);
require('/var/www/moodle/config.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/enrol/locallib.php');
require_once($CFG->dirroot . '/user/lib.php');

global $DB;
$student = $DB->get_record('user', ['username' => 'stackstudent']);
if (!$student) {
    $student = (object)[
        'auth' => 'manual', 'confirmed' => 1, 'mnethostid' => $CFG->mnet_localhost_id,
        'username' => 'stackstudent', 'password' => hash_internal_user_password('StackStudent!52'),
        'firstname' => 'STACK', 'lastname' => 'Student', 'email' => 'stackstudent@example.invalid',
    ];
    $student->id = user_create_user($student, false, false);
}

$course = $DB->get_record_sql("SELECT c.* FROM {course} c JOIN {quiz} q ON q.course = c.id ORDER BY c.id ASC", null, IGNORE_MULTIPLE);
if (!$course) {
    $course = $DB->get_record('course', ['shortname' => 'STACK-MOBILE-DEMO']);
}
if (!$course) {
    $course = create_course((object)[
        'fullname' => 'STACK Mobile Demo', 'shortname' => 'STACK-MOBILE-DEMO',
        'category' => 1, 'visible' => 1, 'format' => 'topics',
    ]);
}

$manual = enrol_get_plugin('manual');
$instance = $DB->get_record('enrol', ['courseid' => $course->id, 'enrol' => 'manual'], '*', MUST_EXIST);
$studentrole = $DB->get_field('role', 'id', ['shortname' => 'student'], MUST_EXIST);
if (!is_enrolled(context_course::instance($course->id), $student)) {
    $manual->enrol_user($instance, $student->id, $studentrole);
}

echo "Enrolled stackstudent in {$course->shortname}.\n";
