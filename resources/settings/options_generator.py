
def generate_options_and_case_code():
    xml = """"""
    monkey = """"""

    start_hr = 13
    end_hr = 23

    cnt = 0
    for hours in range(start_hr, end_hr, 1):
        for minutes in range(0, 60, 30):
            if len(str(hours)) == 1:
                hours = "0"+str(hours)
            if len(str(minutes)) == 1:
                minutes = "0"+str(minutes)
            value = str(hours)+str(minutes)
            value_start = value[:2]
            if value_start.startswith("0"):
                value_start = value_start[1]
            value_end = value[-2:].replace("00", "0")

            xml += f'<listEntry value="{cnt}">"{value}"</listEntry>' + "\n"
            monkey += f"""case {cnt}:
        return [{value_start},{value_end}];\n"""

            cnt += 1

    print(xml)
    print()
    print(monkey)


if __name__ == "__main__":
    generate_options_and_case_code()
