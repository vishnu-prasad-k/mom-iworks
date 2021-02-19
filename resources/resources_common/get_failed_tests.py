import glob, os
from lxml import etree

"""
Retrieve Failed Tags & Attempt Re-Runs In Teamcity Build Step 4
    - Parses output.xml files generated from first round of testing
    - Parses result from <statistics> to detect aggregated failures of Critical Test
        - Failure Test marked as non_critical_test will not count towards Critical Test statistics
    - If Overall Critical Failure Detected:
        - Search for tags marking the failed test cases 
        - Ignore non_critical_test tag failures
    - Else:
        - Skip tag search under assumption of no Overall Critical Failures

Note: If Robot command wasn't configure to ignore 'non_critical_test' and count towards Critical Failure
      Algorithm will ONLY IGNORE non_critical_test tags in the format of:
      <stat pass="0" fail="1" info="non-critical">non_critical_test</stat>
        - Presence of @info="non-critical" and text()='non_critical_test'
"""
if __name__ == "__main__":
    non_crit = 'non_critical_test'
    test_names = []
    test_failure_crit_total = 0
    test_failure_non_crit_total = 0
    failed_tags = ''
    failed_tags_file_name = 'failedtags.txt'

    print("Checking Failed Tag(s) for Re-Run...")
    print("WARNING: {} Tag Will Not Count Towards Critical Failures...".format(non_crit))
    ##### Get Failed Tags and write to file #####
    for filename in glob.iglob(os.path.dirname(os.path.realpath(__file__)) + '/../../results/**/output*.xml',
                               recursive=True):
        if os.path.isfile(filename):  # filter dirs
            with open(filename) as f:
                tree = etree.parse(filename)
                test_name = tree.xpath('//statistics/suite/stat')[0].attrib['name']
                if test_name not in test_names:
                    test_names.append(test_name)
                critical_failures = int(tree.xpath('//statistics/total/stat[text()="Critical Tests"]')[0].attrib['fail'])

                print("{} Total Critical Failures: {}".format(critical_failures, filename))
                if critical_failures > 0:
                    print("Retrieving Failed Tag(s) for Re-Run...")
                    stats = tree.xpath('//statistics/tag/stat')
                    for stat in stats:
                        failures = int(stat.attrib['fail'])
                        if failures > 0:
                            if not (stat.text == non_crit and stat.attrib.get('info') == 'non-critical'):
                                failed_tags += stat.text + ' '
                                test_failure_crit_total += failures
                                print(" - Adding Failed Tag(s): {} ({} Failures).".format(stat.text, failures))
                            else:
                                test_failure_non_crit_total += failures
                                print(" - Ignoring: {} ({} Failures)".format(non_crit, failures))
                        else:
                            print(" - Skipping: {} ({} Failures)".format(stat.text, failures))

    failed_tags_file = open(failed_tags_file_name, "w")
    failed_tags_file.writelines(failed_tags.strip())
    failed_tags_file.close()
    failed_tags_file = open(failed_tags_file_name, "r")
    file_content = failed_tags_file.read()

    msg_test_names = 'Nil' if not test_names else ' & '.join(test_names)
    print("---- Test Suite: {} -----".format(msg_test_names))
    print("Total Failures (Critical):", test_failure_crit_total)
    print("Total Failures (Non-Critical):", test_failure_non_crit_total)
    print("Failed Tag(s) File: {}".format(file_content))
    tags_str = 'Nil' if failed_tags.strip() == '' else '\n - ' + failed_tags.strip().replace(' ', '\n - ')
    print("All Failed Tag(s): {}".format(tags_str))
else:
    exit(1)

