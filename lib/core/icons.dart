import 'package:flutter/material.dart';

/// Material-backed icon set exposed under the `LucideIcons.*` names the app
/// already uses.
///
/// The `lucide_icons` pub package subclasses [IconData], which Flutter 3.44
/// made a `final` class — so it no longer compiles. This shim keeps every call
/// site identical while mapping to the built-in (outlined) Material icons,
/// which fit the app's clean aesthetic.
class LucideIcons {
  LucideIcons._();

  static const IconData graduationCap = Icons.school_outlined;
  static const IconData fileText = Icons.description_outlined;
  static const IconData trendingUp = Icons.trending_up_rounded;
  static const IconData zap = Icons.bolt_outlined;
  static const IconData arrowRight = Icons.arrow_forward_rounded;
  static const IconData arrowLeft = Icons.arrow_back_rounded;
  static const IconData mail = Icons.mail_outline_rounded;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData eye = Icons.visibility_outlined;
  static const IconData eyeOff = Icons.visibility_off_outlined;
  static const IconData user = Icons.person_outline_rounded;
  static const IconData building2 = Icons.apartment_rounded;
  static const IconData mapPin = Icons.location_on_outlined;
  static const IconData bookOpen = Icons.menu_book_rounded;
  static const IconData bookMarked = Icons.auto_stories_rounded;
  static const IconData bookmark = Icons.bookmark_outline_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData home = Icons.home_outlined;
  static const IconData layoutGrid = Icons.grid_view_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData searchX = Icons.search_off_rounded;
  static const IconData folder = Icons.folder_outlined;
  static const IconData folderOpen = Icons.folder_open_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData image = Icons.image_outlined;
  static const IconData file = Icons.insert_drive_file_outlined;
  static const IconData alignLeft = Icons.notes_rounded;
  static const IconData upload = Icons.file_upload_outlined;
  static const IconData download = Icons.file_download_outlined;
  static const IconData plus = Icons.add_rounded;
  static const IconData hash = Icons.tag_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData x = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_outline_rounded;
  static const IconData alertCircle = Icons.error_outline_rounded;
  static const IconData paperclip = Icons.attach_file_rounded;
  static const IconData type = Icons.title_rounded;
  static const IconData logOut = Icons.logout_rounded;
  static const IconData moon = Icons.dark_mode_outlined;
  static const IconData sun = Icons.light_mode_outlined;
}
