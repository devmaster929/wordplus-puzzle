import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wordle/bloc/main/main_cubit.dart';
import 'package:wordle/data/models/flushbar_types.dart';
import 'package:wordle/presentation/pages/main/widgets/keyboard_en.dart';
import 'package:wordle/presentation/pages/main/widgets/keyboard_ru.dart';
import 'package:wordle/presentation/pages/main/widgets/word_grid.dart';
import 'package:wordle/presentation/widgets/adaptive_scaffold.dart';
import 'package:wordle/presentation/widgets/dialogs/top_flush_bar.dart';
import 'package:wordle/resources/r.dart';
import 'package:wordle/utils/utils.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      showDialogIfNeed(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainCubit>(
      create: (BuildContext context) => MainCubit(),
      child: AdaptiveScaffold(
        child: Center(
          child: BlocConsumer<MainCubit, MainState>(
            listener: (context, state) {
              if (state is TopMessageState) {
                switch (state.type) {
                  case FlushBarTypes.notFound:
                    showTopFlushBar(
                      context,
                      message: R.stringsOf(context).word_not_found,
                    );
                    break;
                  case FlushBarTypes.notCorrectLength:
                    showTopFlushBar(
                      context,
                      message: R.stringsOf(context).word_too_short,
                    );
                    break;
                }
              } else if (state is WinGameState) {
                showDialogIfNeed(context, isWin: true);
              } else if (state is LoseGameState) {
                showDialogIfNeed(context, isWin: false);
              }
            },
            buildWhen: (_, currState) => currState is ChangeDictionaryState,
            builder: (context, state) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  key: UniqueKey(),
                  children: [
                    const SizedBox(height: 16),
                    const WordGrid(),
                    const Spacer(),
                    BlocBuilder<MainCubit, MainState>(
                      buildWhen: (previous, current) =>
                          current is ChangeDictionaryState,
                      builder: (context, state) => _getKeyboardByLanguage(
                        state is! ChangeDictionaryState
                            ? "en"
                            : state.dictionary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getKeyboardByLanguage(final String language) {
    switch (language) {
      case "ru":
        return const KeyboardRu();
      case "en":
      default:
        return const KeyboardEn();
    }
  }
}
