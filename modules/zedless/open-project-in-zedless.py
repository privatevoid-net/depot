import subprocess

from urllib.parse import urlparse, parse_qs
from sys import argv
import os
import re

ZENITY = "@zenity@"
GIT_PROGRESS_LINE = re.compile(
    "^(?P<action>.*): +(?P<percentage>\\d+)% \\((?P<done>\\d+)/(?P<total>\\d+)\\)(?P<endmarker>, .*)?$"
)


def die(msg, context=None):
    if context:
        print(f"{msg}: '{context}'")
    else:
        print(msg)
    exit(1)


def displayZenityError(msg, context=None, long=False):
    args = []
    if context and long:
        args = [
            ZENITY,
            "--text-info",
            "--width=600",
            "--height=400",
            "--cancel-label=Retry",
            "--ok-label=OK",
            f"--title={msg}",
        ]
        cmd = subprocess.run(args, input=context.encode())
    else:
        args = [
            ZENITY,
            "--error",
            "--width=600",
        ]
        if context:
            args.append(f"--title={msg}")
            args.append(f"--text={context}")
        else:
            args.append(f"--text={msg}")
        cmd = subprocess.run(args)
    return cmd.returncode == 0


def run(args):
    cmd = subprocess.run(args)
    return cmd.returncode == 0


def gitCloneWithProgress(projectUrl, projectDir):
    while True:
        args = [
            "git",
            "clone",
            "--progress",
            projectUrl,
            projectDir,
        ]
        cmd = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            universal_newlines=True,
        )
        zenity = subprocess.Popen(
            [
                ZENITY,
                "--progress",
                "--width=600",
                "--pulsate",
                "--text=Waiting...",
                "--auto-kill",
                "--title=Cloning project",
            ],
            stdin=subprocess.PIPE,
            text=True,
        )
        log = [f"$ git clone {projectUrl} {projectDir}"]
        pulsate = True
        if cmd.stdout and zenity.stdin:
            while True:
                line = cmd.stdout.readline()
                if line:
                    line = line.strip()
                    log.append(line)
                    res = GIT_PROGRESS_LINE.match(line)
                    if res:
                        endmarker = res.group("endmarker")
                        if endmarker == ", done.":
                            if not pulsate:
                                zenity.stdin.writelines(["pulsate:true\n"])
                                pulsate = True
                        else:
                            if pulsate:
                                zenity.stdin.writelines(["pulsate:false\n"])
                                pulsate = False
                        zenity.stdin.writelines(
                            [f"# {line}\n", res.group("percentage") + "\n"]
                        )
                        zenity.stdin.flush()
                    else:
                        if not pulsate:
                            zenity.stdin.writelines(["pulsate:true\n"])
                            pulsate = True
                        zenity.stdin.writelines([f"#{line}\n"])
                else:
                    break
        exitcode = cmd.wait()
        zenity.terminate()
        if exitcode != 0:
            if displayZenityError("Failed to clone repository", "\n".join(log), True):
                return exitcode == 0
        else:
            return True


url = urlparse(argv[1])

if url.scheme != "vscode" and url.scheme != "vscodium":
    die("Unsupported url scheme", url.scheme)

if url.netloc != "vscode.git":
    die("Unsupported netloc", url.netloc)

if url.path != "/clone":
    die("Unsupported path", url.path)

q = parse_qs(url.query)

if "url" not in q:
    die("Missing url parameter in query string", q)

url2 = urlparse(q["url"][0])

projectDir = None

homedir = os.environ["HOME"]

if url2.scheme == "ssh" or (url2.scheme == "" and url2.netloc == ""):
    if url2.scheme == "ssh":
        host = url2.netloc.split("@", maxsplit=1)[1].removeprefix("ssh.")
        sanePath = url2.path.removesuffix(".git")
        projectUrl = f"{url2.scheme}://{url2.netloc}{url2.path}"
        projectDir = f"{homedir}/Projects/{host}{sanePath}"
    else:
        split1 = url2.path.split("@", maxsplit=1)
        split2 = split1[1].split(":")
        user = split1[0]
        host = split2[0]
        path = split2[1]
        sanePath = path.removesuffix(".git")
        projectUrl = f"ssh://{user}@{host}/{path}"
        projectDir = f"{homedir}/Projects/{host}/{sanePath}"
    if not os.path.exists(f"{projectDir}/.git"):
        if not gitCloneWithProgress(
            projectUrl,
            projectDir,
        ):
            die("Failed to clone repository")
elif url2.scheme == "https":
    host = url2.netloc
    sanePath = url2.path.removesuffix(".git")
    projectDir = f"{homedir}/Projects/{host}{sanePath}"
    if not os.path.exists(f"{projectDir}/.git"):
        if not gitCloneWithProgress(
            f"{url2.scheme}://{url2.netloc}{url2.path}",
            projectDir,
        ):
            die("Failed to clone repository")

if not projectDir:
    die("Don't know how to clone repository", url2)

if not os.path.exists(f"{projectDir}/.git"):
    die("Bug: Git reported success, but repo does not exist")

if os.path.exists(f"{projectDir}/.envrc"):
    print("Enabling direnv")
    run(["direnv", "allow", projectDir])
elif os.path.exists(f"{projectDir}/flake.nix"):
    print("Writing local direnv configuration for flake devShell")
    run(["bash", "-c", f"cd {projectDir} && use flake"])

run(["zedless", projectDir])
