// US-PIPE-06 / US-JX-08: a JUnit report with a pass, a failure with a
// stack trace, and a skip. The build goes UNSTABLE.
pipeline {
  agent any
  stages {
    stage('Test') {
      steps {
        writeFile file: 'reports/TEST-fixture.xml', text: '''<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="com.jobtrigger.CalcTest" tests="4" failures="1" skipped="1">
  <testcase classname="com.jobtrigger.CalcTest" name="adds" time="0.01"/>
  <testcase classname="com.jobtrigger.CalcTest" name="subtracts" time="0.01"/>
  <testcase classname="com.jobtrigger.CalcTest" name="divides" time="0.02">
    <failure message="expected:&lt;2&gt; but was:&lt;3&gt;" type="java.lang.AssertionError">java.lang.AssertionError: expected:&lt;2&gt; but was:&lt;3&gt;
    at com.jobtrigger.CalcTest.divides(CalcTest.java:42)</failure>
  </testcase>
  <testcase classname="com.jobtrigger.CalcTest" name="flaky" time="0">
    <skipped/>
  </testcase>
</testsuite>
'''
        junit 'reports/*.xml'
      }
    }
  }
}
