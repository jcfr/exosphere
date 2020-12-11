import os
import pathlib

from behave import then, when, step
from behaving.personas.persona import persona_vars
from behaving.web.steps import i_press_xpath


@step('I pause for a breakpoint')
def i_pause_for_breakpoint(context):
    print('Stopping for a breakpoint')
    import pydevd_pycharm
    pydevd_pycharm.settrace('localhost', port=4567, stdoutToServer=True,
                            stderrToServer=True, suspend=True)


@step('I enable breakpoints')
def i_enable_breakpoints(context):
    print('Enabling breakpoints')
    import pydevd_pycharm
    pydevd_pycharm.settrace('localhost', port=4567, stdoutToServer=True,
                            stderrToServer=True, suspend=False)


@when('I go to Exosphere')
def i_go_to_exosphere(context):
    exosphere_url = context.config.userdata.get('EXOSPHERE_BASE_URL',
                                                'https://try.exosphere.app/exosphere')
    context.browser.visit(exosphere_url)


def find_by_label(context, label, element_type, wait_time=None):
    return context.browser.find_by_xpath(
        xpath=f"//label[contains(string(),'{label}')]//{element_type}",
        wait_time=wait_time
    )


def find_input_by_label(context, label, wait_time=None):
    return find_by_label(
        context=context,
        label=label,
        element_type='input',
        wait_time=wait_time)


@step(u'I fill input labeled "{label}" with "{value}"')
@persona_vars
def i_fill_input_labeled(context, label, value):
    element = find_input_by_label(context, label).first
    element.fill(value)


def find_element_with_role_and_label(context, role, label, wait_time=None):
    return context.browser.find_by_xpath(
        xpath=f"//div[@role='{role}']//div[contains(string(), '{label}')]",
        wait_time=wait_time
    )


def find_button_with_label(context, label, wait_time=None):
    return find_element_with_role_and_label(
        context=context,
        role='button',
        label=label,
        wait_time=wait_time
    )


def find_checkbox_with_label(context, label, wait_time=None):
    return context.browser.find_by_xpath(
        xpath=f"//label[contains(string(), '{label}')]//div[@role='checkbox']",
        wait_time=wait_time)


def find_radio_with_label(context, label, wait_time=None):
    return context.browser.find_by_xpath(
        xpath=f"//div[@role='radio' and contains(string(), '{label}')]",
        wait_time=wait_time)


@step(u'I click the "{label}" button')
@persona_vars
def i_press_label_button(context, label):
    all_elements = find_button_with_label(context, label)
    case_insensitive_elements = [e for e in all_elements if
                                 str.upper(e.text) == str.upper(label)]
    case_sensitive_elements = [e for e in all_elements if e.text == label]
    elements = case_sensitive_elements or case_insensitive_elements
    if elements:
        element = elements[0]
    else:
        element = all_elements.first
    element.click()


@step(u'I click the last "{label}" button')
@persona_vars
def i_press_last_label_button(context, label):
    all_elements = find_button_with_label(context, label)
    case_insensitive_elements = [e for e in all_elements if
                                 str.upper(e.text) == str.upper(label)]
    case_sensitive_elements = [e for e in all_elements if e.text == label]
    elements = case_sensitive_elements or case_insensitive_elements
    if elements:
        element = elements[-1]
    else:
        element = all_elements.last
    element.click()


@step(u'I press the last element with xpath "{xpath}"')
@persona_vars
def i_press_last_xpath(context, xpath):
    button = context.browser.find_by_xpath(xpath)
    assert button, u"Element not found"
    button.last.click()


@step(u'I click the "{label}" checkbox')
@persona_vars
def i_press_label_checkbox(context, label):
    element = find_checkbox_with_label(context, label).first
    element.click()


@step(u'I click the "{label}" radio button')
@persona_vars
def i_press_label_radiobutton(context, label):
    element = find_radio_with_label(context, label).first
    element.click()


@step("I enter TACC credentials")
@persona_vars
def i_login_to_exosphere(context):
    taccusername = os.environ.get('taccusername')
    taccpass = os.environ.get('taccpass')
    context.execute_steps(f"""
    Then I fill input labeled "TACC Username" with "{taccusername}"
    And I fill input labeled "TACC Password" with "{taccpass}"
    """)


@step('I save the "{local_storage_item}" item in browser local storage')
@persona_vars
def i_save_local_storage(context, local_storage_item):
    local_storage_item_content = context.browser.evaluate_script(
        f"localStorage.getItem('{local_storage_item}')")
    with open(f'/tmp/{local_storage_item}', 'w') as temporary_file:
        temporary_file.write(local_storage_item_content)


@step('I load the "{local_storage_item}" item in browser local storage')
@persona_vars
def i_load_local_storage(context, local_storage_item):
    with open(f'/tmp/{local_storage_item}', 'r') as temporary_file:
        local_storage_item_content = temporary_file.read()
        context.browser.evaluate_script(
            f"localStorage.setItem('{local_storage_item}', '{local_storage_item_content}')")
        context.browser.reload()


@step('I delete "{local_storage_item}" browser local storage item file')
@persona_vars
def i_delete_local_storage_file(context, local_storage_item):
    file_path = pathlib.Path(f'/tmp/{local_storage_item}')
    try:
        file_path.unlink()
    except FileNotFoundError:
        # Ignore if the file we're trying to delete does not exist.
        pass
