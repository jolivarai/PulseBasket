#!/usr/bin/env python3
"""
Añade el target de extensión `PulsoWidget` al proyecto Xcode de Flutter.

No se ejecuta en el móvil ni hace falta en macOS: el repo ya trae el
project.pbxproj parcheado. Este script existe para (1) poder auditar qué se
añadió y (2) poder re-aplicar el parche si alguien devuelve el pbxproj al
estado de `flutter create`.

Uso:  python3 scripts/parche_widget.py [ruta/al/project.pbxproj]
Comprueba: python3 scripts/parche_widget.py --check
"""
import re
import sys

# ─────────────────────────────────────────────── IDs estables (24 hex) ──
T_TARGET   = "4A9F1C0000000000000000A1"
T_PRODUCT  = "4A9F1C0000000000000000A2"
T_SOURCES  = "4A9F1C0000000000000000A3"
T_FRAMES   = "4A9F1C0000000000000000A4"
T_RES      = "4A9F1C0000000000000000A5"
T_CFGLIST  = "4A9F1C0000000000000000A6"
T_DEBUG    = "4A9F1C0000000000000000A7"
T_RELEASE  = "4A9F1C0000000000000000A8"
T_PROFILE  = "4A9F1C0000000000000000A9"
T_GROUP    = "4A9F1C0000000000000000B1"
F_BUNDLE   = "4A9F1C0000000000000000B2"
F_VIEW     = "4A9F1C0000000000000000B3"
F_PLIST    = "4A9F1C0000000000000000B4"
F_ENT      = "4A9F1C0000000000000000B5"
B_BUNDLE   = "4A9F1C0000000000000000B6"
B_VIEW     = "4A9F1C0000000000000000B7"
B_ATTR_W   = "4A9F1C0000000000000000B8"
B_INTENT_W = "4A9F1C0000000000000000B9"
F_INTENT   = "4A9F1C0000000000000000BA"
B_INTENT_A = "4A9F1C0000000000000000BB"
T_EMBED    = "4A9F1C0000000000000000C1"
B_APPEX    = "4A9F1C0000000000000000C2"
T_PROXY    = "4A9F1C0000000000000000C3"
T_DEP      = "4A9F1C0000000000000000C4"

F_ATTRS    = "5C594BDEA527E5C8A1D21E38"   # ya existe: Runner/PulsoActivityAttributes.swift
RUNNER     = "97C146ED1CF9000F007C117D"
RUNNER_G   = "97C146F01CF9000F007C117D"
MAIN_G     = "97C146E51CF9000F007C117D"
PRODUCTS_G = "97C146EF1CF9000F007C117D"
PROJECT    = "97C146E61CF9000F007C117D"
RUNNER_RES = "97C146EC1CF9000F007C117D"
EMBED_FW   = "9705A1C41CF9048500538489"

BUILD_SETTINGS = """\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = PulsoWidget/PulsoWidget.entitlements;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = PulsoWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.1;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.pulso.basket.PulsoWidget;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tVERSIONING_SYSTEM = "apple-generic";"""


def insert_before(text, marker, block):
    """Inserta `block` justo antes del primer `marker`."""
    i = text.index(marker)
    return text[:i] + block + text[i:]


def patch(text):
    if T_TARGET in text:
        return text, "ya estaba parcheado"

    # 1. PBXBuildFile -------------------------------------------------------
    text = insert_before(text, "/* End PBXBuildFile section */", (
        f"\t\t{B_BUNDLE} /* PulsoWidgetBundle.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {F_BUNDLE} /* PulsoWidgetBundle.swift */; }};\n"
        f"\t\t{B_VIEW} /* PulsoLiveActivityView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {F_VIEW} /* PulsoLiveActivityView.swift */; }};\n"
        f"\t\t{B_ATTR_W} /* PulsoActivityAttributes.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {F_ATTRS} /* PulsoActivityAttributes.swift */; }};\n"
        f"\t\t{B_INTENT_W} /* PulsoCommandIntent.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {F_INTENT} /* PulsoCommandIntent.swift */; }};\n"
        f"\t\t{B_INTENT_A} /* PulsoCommandIntent.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {F_INTENT} /* PulsoCommandIntent.swift */; }};\n"
        f"\t\t{B_APPEX} /* PulsoWidget.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {T_PRODUCT} /* PulsoWidget.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n"
    ))

    # 2. PBXContainerItemProxy ---------------------------------------------
    text = insert_before(text, "/* End PBXContainerItemProxy section */", (
        f"\t\t{T_PROXY} /* PBXContainerItemProxy */ = {{\n"
        "\t\t\tisa = PBXContainerItemProxy;\n"
        f"\t\t\tcontainerPortal = {PROJECT} /* Project object */;\n"
        "\t\t\tproxyType = 1;\n"
        f"\t\t\tremoteGlobalIDString = {T_TARGET};\n"
        "\t\t\tremoteInfo = PulsoWidget;\n"
        "\t\t};\n"
    ))

    # 3. PBXCopyFilesBuildPhase (embed) ------------------------------------
    text = insert_before(text, "/* End PBXCopyFilesBuildPhase section */", (
        f"\t\t{T_EMBED} /* Embed App Extensions */ = {{\n"
        "\t\t\tisa = PBXCopyFilesBuildPhase;\n"
        "\t\t\tbuildActionMask = 2147483647;\n"
        "\t\t\tdstPath = \"\";\n"
        "\t\t\tdstSubfolderSpec = 13;\n"
        "\t\t\tfiles = (\n"
        f"\t\t\t\t{B_APPEX} /* PulsoWidget.appex in Embed App Extensions */,\n"
        "\t\t\t);\n"
        "\t\t\tname = \"Embed App Extensions\";\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
    ))

    # 4. PBXFileReference --------------------------------------------------
    text = insert_before(text, "/* End PBXFileReference section */", (
        f"\t\t{T_PRODUCT} /* PulsoWidget.appex */ = {{isa = PBXFileReference; explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = PulsoWidget.appex; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
        f"\t\t{F_BUNDLE} /* PulsoWidgetBundle.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PulsoWidgetBundle.swift; sourceTree = \"<group>\"; }};\n"
        f"\t\t{F_VIEW} /* PulsoLiveActivityView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PulsoLiveActivityView.swift; sourceTree = \"<group>\"; }};\n"
        f"\t\t{F_PLIST} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};\n"
        f"\t\t{F_ENT} /* PulsoWidget.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = PulsoWidget.entitlements; sourceTree = \"<group>\"; }};\n"
        f"\t\t{F_INTENT} /* PulsoCommandIntent.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PulsoCommandIntent.swift; sourceTree = \"<group>\"; }};\n"
    ))

    # 5. PBXFrameworksBuildPhase del widget --------------------------------
    text = insert_before(text, "/* End PBXFrameworksBuildPhase section */", (
        f"\t\t{T_FRAMES} /* Frameworks */ = {{\n"
        "\t\t\tisa = PBXFrameworksBuildPhase;\n"
        "\t\t\tbuildActionMask = 2147483647;\n"
        "\t\t\tfiles = (\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
    ))

    # 6. PBXGroup del widget ----------------------------------------------
    text = insert_before(text, "/* End PBXGroup section */", (
        f"\t\t{T_GROUP} /* PulsoWidget */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        f"\t\t\t\t{F_BUNDLE} /* PulsoWidgetBundle.swift */,\n"
        f"\t\t\t\t{F_VIEW} /* PulsoLiveActivityView.swift */,\n"
        f"\t\t\t\t{F_ENT} /* PulsoWidget.entitlements */,\n"
        f"\t\t\t\t{F_PLIST} /* Info.plist */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = PulsoWidget;\n"
        "\t\t\tsourceTree = \"<group>\";\n"
        "\t\t};\n"
    ))

    # 7. Referencias dentro de grupos existentes ---------------------------
    text = text.replace(
        f"\t\t\t\t{PRODUCTS_G} /* Products */,\n\t\t\t);",
        f"\t\t\t\t{PRODUCTS_G} /* Products */,\n\t\t\t\t{T_GROUP} /* PulsoWidget */,\n\t\t\t);",
        1,
    )
    text = text.replace(
        f"\t\t\t\t97C146EE1CF9000F007C117D /* Runner.app */,\n"
        f"\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,\n",
        f"\t\t\t\t97C146EE1CF9000F007C117D /* Runner.app */,\n"
        f"\t\t\t\t{T_PRODUCT} /* PulsoWidget.appex */,\n"
        f"\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,\n",
        1,
    )
    text = text.replace(
        f"\t\t\t\t74858FAD1ED2DC5600515810 /* Runner-Bridging-Header.h */,\n",
        f"\t\t\t\t74858FAD1ED2DC5600515810 /* Runner-Bridging-Header.h */,\n"
        f"\t\t\t\t{F_INTENT} /* PulsoCommandIntent.swift */,\n",
        1,
    )

    # 8. PBXNativeTarget del widget ---------------------------------------
    text = insert_before(text, "/* End PBXNativeTarget section */", (
        f"\t\t{T_TARGET} /* PulsoWidget */ = {{\n"
        "\t\t\tisa = PBXNativeTarget;\n"
        f"\t\t\tbuildConfigurationList = {T_CFGLIST} /* Build configuration list for PBXNativeTarget \"PulsoWidget\" */;\n"
        "\t\t\tbuildPhases = (\n"
        f"\t\t\t\t{T_SOURCES} /* Sources */,\n"
        f"\t\t\t\t{T_FRAMES} /* Frameworks */,\n"
        f"\t\t\t\t{T_RES} /* Resources */,\n"
        "\t\t\t);\n"
        "\t\t\tbuildRules = (\n"
        "\t\t\t);\n"
        "\t\t\tdependencies = (\n"
        "\t\t\t);\n"
        "\t\t\tname = PulsoWidget;\n"
        "\t\t\tproductName = PulsoWidget;\n"
        f"\t\t\tproductReference = {T_PRODUCT} /* PulsoWidget.appex */;\n"
        "\t\t\tproductType = \"com.apple.product-type.app-extension\";\n"
        "\t\t};\n"
    ))

    # 9. Runner: dependencia + fase de embebido + fuente del intent -------
    text = text.replace(
        f"\t\t\t\t{EMBED_FW} /* Embed Frameworks */,\n"
        f"\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,\n",
        f"\t\t\t\t{T_EMBED} /* Embed App Extensions */,\n"
        f"\t\t\t\t{EMBED_FW} /* Embed Frameworks */,\n"
        f"\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,\n",
        1,
    )
    text = text.replace(
        f"\t\t\tproductReference = 97C146EE1CF9000F007C117D /* Runner.app */;\n",
        f"\t\t\tproductReference = 97C146EE1CF9000F007C117D /* Runner.app */;\n",
        1,
    )
    # dependencies del Runner (está vacío: `dependencies = (\n\t\t\t);` justo
    # antes de name = Runner)
    text = text.replace(
        "\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = Runner;\n",
        "\t\t\tdependencies = (\n"
        f"\t\t\t\t{T_DEP} /* PBXTargetDependency */,\n"
        "\t\t\t);\n\t\t\tname = Runner;\n",
        1,
    )
    # PulsoCommandIntent también en Sources del Runner
    text = text.replace(
        f"\t\t\t\t8E6948A09FC766366F4521D7 /* PulsoActivityAttributes.swift in Sources */,\n",
        f"\t\t\t\t8E6948A09FC766366F4521D7 /* PulsoActivityAttributes.swift in Sources */,\n"
        f"\t\t\t\t{B_INTENT_A} /* PulsoCommandIntent.swift in Sources */,\n",
        1,
    )

    # 10. PBXProject: target + atributos ----------------------------------
    text = text.replace(
        f"\t\t\t\t{RUNNER} /* Runner */,\n\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,\n\t\t\t);",
        f"\t\t\t\t{RUNNER} /* Runner */,\n\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,\n\t\t\t\t{T_TARGET} /* PulsoWidget */,\n\t\t\t);",
        1,
    )
    text = text.replace(
        f"\t\t\t\t\t97C146ED1CF9000F007C117D = {{\n"
        "\t\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;\n"
        "\t\t\t\t\t\tLastSwiftMigration = 1100;\n"
        "\t\t\t\t\t};\n",
        f"\t\t\t\t\t97C146ED1CF9000F007C117D = {{\n"
        "\t\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;\n"
        "\t\t\t\t\t\tLastSwiftMigration = 1100;\n"
        "\t\t\t\t\t};\n"
        f"\t\t\t\t\t{T_TARGET} = {{\n"
        "\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;\n"
        "\t\t\t\t\t};\n",
        1,
    )

    # 11. PBXResourcesBuildPhase del widget -------------------------------
    text = insert_before(text, "/* End PBXResourcesBuildPhase section */", (
        f"\t\t{T_RES} /* Resources */ = {{\n"
        "\t\t\tisa = PBXResourcesBuildPhase;\n"
        "\t\t\tbuildActionMask = 2147483647;\n"
        "\t\t\tfiles = (\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
    ))

    # 12. PBXSourcesBuildPhase del widget ---------------------------------
    text = insert_before(text, "/* End PBXSourcesBuildPhase section */", (
        f"\t\t{T_SOURCES} /* Sources */ = {{\n"
        "\t\t\tisa = PBXSourcesBuildPhase;\n"
        "\t\t\tbuildActionMask = 2147483647;\n"
        "\t\t\tfiles = (\n"
        f"\t\t\t\t{B_BUNDLE} /* PulsoWidgetBundle.swift in Sources */,\n"
        f"\t\t\t\t{B_VIEW} /* PulsoLiveActivityView.swift in Sources */,\n"
        f"\t\t\t\t{B_ATTR_W} /* PulsoActivityAttributes.swift in Sources */,\n"
        f"\t\t\t\t{B_INTENT_W} /* PulsoCommandIntent.swift in Sources */,\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
    ))

    # 13. PBXTargetDependency --------------------------------------------
    text = insert_before(text, "/* End PBXTargetDependency section */", (
        f"\t\t{T_DEP} /* PBXTargetDependency */ = {{\n"
        "\t\t\tisa = PBXTargetDependency;\n"
        f"\t\t\ttarget = {T_TARGET} /* PulsoWidget */;\n"
        f"\t\t\ttargetProxy = {T_PROXY} /* PBXContainerItemProxy */;\n"
        "\t\t};\n"
    ))

    # 14. Configuraciones de build del widget -----------------------------
    cfgs = ""
    for uid, name, extra in (
        (T_DEBUG, "Debug", "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";\n"),
        (T_RELEASE, "Release", ""),
        (T_PROFILE, "Profile", ""),
    ):
        cfgs += (
            f"\t\t{uid} /* {name} */ = {{\n"
            "\t\t\tisa = XCBuildConfiguration;\n"
            "\t\t\tbuildSettings = {\n"
            f"{BUILD_SETTINGS}\n{extra}"
            "\t\t\t};\n"
            f"\t\t\tname = {name};\n"
            "\t\t};\n"
        )
    text = insert_before(text, "/* End XCBuildConfiguration section */", cfgs)

    # 15. XCConfigurationList del widget ----------------------------------
    text = insert_before(text, "/* End XCConfigurationList section */", (
        f"\t\t{T_CFGLIST} /* Build configuration list for PBXNativeTarget \"PulsoWidget\" */ = {{\n"
        "\t\t\tisa = XCConfigurationList;\n"
        "\t\t\tbuildConfigurations = (\n"
        f"\t\t\t\t{T_DEBUG} /* Debug */,\n"
        f"\t\t\t\t{T_RELEASE} /* Release */,\n"
        f"\t\t\t\t{T_PROFILE} /* Profile */,\n"
        "\t\t\t);\n"
        "\t\t\tdefaultConfigurationIsVisible = 0;\n"
        "\t\t\tdefaultConfigurationName = Release;\n"
        "\t\t};\n"
    ))

    return text, "parcheado"


def audit(text):
    """Verifica integridad: IDs definidos vs. referenciados y llaves."""
    defined = set(re.findall(r"^\t\t([0-9A-F]{24}) ", text, re.M))
    referenced = set(re.findall(r"\b([0-9A-F]{24})\b", text))
    dangling = sorted(referenced - defined)
    problems = []
    if text.count("{") != text.count("}"):
        problems.append(f"llaves desbalanceadas: {text.count('{')} abren, {text.count('}')} cierran")
    if dangling:
        problems.append(f"referencias huérfanas: {dangling}")
    if text.count(f"{T_SOURCES} /* Sources */,") < 1:
        problems.append("fase Sources del widget ausente")
    if f"{T_APPEX_MARKER}" not in text:
        problems.append("falta el embed del .appex")
    return problems


T_APPEX_MARKER = f"{B_APPEX} /* PulsoWidget.appex in Embed App Extensions */ = {{"

if __name__ == "__main__":
    path = "ios/Runner.xcodeproj/project.pbxproj"
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if args:
        path = args[0]

    src = open(path, encoding="utf-8").read()

    if "--check" in sys.argv:
        problems = audit(src)
        print("target PulsoWidget:", "PRESENTE" if T_TARGET in src else "AUSENTE")
        print("problemas:", problems or "ninguno")
        sys.exit(0 if not problems else 1)

    out, status = patch(src)
    problems = audit(out)
    if problems:
        print("ABORTADO, el resultado no es válido:", problems)
        sys.exit(1)
    open(path + ".bak", "w", encoding="utf-8").write(src)
    open(path, "w", encoding="utf-8").write(out)
    print(f"{status}; backup en {path}.bak")
