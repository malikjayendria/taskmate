import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/group_service.dart';
import 'services/task_service.dart';
import 'services/user_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/group_viewmodel.dart';
import 'viewmodels/task_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'views/auth/auth_flow_view.dart';
import 'views/groups/group_dashboard_view.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TaskMateApp());
}

class TaskMateApp extends StatelessWidget {
  const TaskMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => UserService()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthViewModel(AuthService(), context.read<UserService>())
                ..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserViewModel(context.read<UserService>()),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, GroupViewModel>(
          create: (_) => GroupViewModel(GroupService()),
          update: (_, auth, groupViewModel) {
            groupViewModel ??= GroupViewModel(GroupService());
            groupViewModel.attachUser(auth.currentUser?.uid);
            return groupViewModel;
          },
        ),
        ChangeNotifierProxyProvider2<
          GroupViewModel,
          AuthViewModel,
          TaskViewModel
        >(
          create: (_) => TaskViewModel(TaskService()),
          update: (_, groupViewModel, authViewModel, taskViewModel) {
            taskViewModel ??= TaskViewModel(TaskService());
            taskViewModel.setContext(
              groupId: groupViewModel.selectedGroupId,
              viewer: authViewModel.currentUser,
            );
            return taskViewModel;
          },
        ),
      ],
      child: MaterialApp(
        title: 'TaskMate - Tugas Kelompok',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RootRouter(),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    if (authViewModel.currentUser == null) {
      return const AuthFlowView();
    }

    return const GroupDashboardView();
  }
}
