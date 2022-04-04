import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:wordly/data/models/flushbar_types.dart';
import 'package:wordly/data/models/keyboard_keys.dart';
import 'package:wordly/data/models/letter_status.dart';
import 'package:wordly/data/repositories/dictionary_repository.dart';
import 'package:wordly/domain/board_repository.dart';
import 'package:wordly/domain/daily_result_repository.dart';
import 'package:wordly/domain/daily_statistic_repository.dart';
import 'package:wordly/domain/level_repository.dart';
import 'package:wordly/domain/settings_repository.dart';

part 'main_state.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit(this.dictionaryRepository) : super(MainInitial());
  final DictionaryRepository dictionaryRepository;

  void setLetter(final KeyboardKeys keyboardKey) {
    if (dictionaryRepository.setLetter(keyboardKey)) {
      emit(GridUpdateState());
    }
  }

  void removeLetter() {
    dictionaryRepository.removeLetter();
    emit(GridUpdateState());
  }

  void removeFullWord() {
    dictionaryRepository.removeFullWord();
    emit(GridUpdateState());
  }

  void updateKey(final KeyboardKeys key, final LetterStatus letterStatus) {
    emit(KeyboardKeyUpdateState(key, letterStatus));
  }

  bool completeWord() {
    final levelRepository = GetIt.I<LevelRepository>();
    final settingsRepository = GetIt.I<SettingsRepository>();
    final dailyResultRepository = GetIt.I<DailyResultRepository>();
    final dailyStatisticRepository = GetIt.I<DailyStatisticRepository>();
    final state = dictionaryRepository.completeWord();
    if (state == null) {
      return false;
    }
    if (state is GridUpdateState ||
        state is WinGameState ||
        state is LoseGameState) {
      dictionaryRepository.saveBoard();
      emit(state);
      if (state is WinGameState || state is LoseGameState) {
        if (levelRepository.isLevelMode) {
          levelRepository.saveLevelData();
        } else {
          final dictionaryLanguage =
              settingsRepository.settingsData.dictionaryLanguage;
          dailyResultRepository.saveDailyResult(
            isWin: state is WinGameState,
            word: dictionaryRepository.secretWord,
            language: dictionaryLanguage,
          );
          dailyStatisticRepository.saveStatisticData(
            isWin: state is WinGameState,
            attempt: dictionaryRepository.currentAttempt,
          );
        }
        emit(GridUpdateState());
      }
      return true;
    } else if (state is TopMessageState) {
      emit(state);
    }
    return false;
  }

  Future<void> loadDaily() async {
    final settingsRepository = GetIt.I<SettingsRepository>();
    final boardRepository = GetIt.I<BoardRepository>();
    final levelRepository = GetIt.I<LevelRepository>();

    levelRepository.levelMode = false;
    final dictionaryLanguage =
        settingsRepository.settingsData.dictionaryLanguage;
    dictionaryRepository.resetData();
    dictionaryRepository.createSecretWord();
    await boardRepository.initBoardData(
      dictionaryLanguage: dictionaryLanguage,
      levelNumber: 0,
    );
    dictionaryRepository.loadBoard();
    emit(GridUpdateState());
  }

  Future<void> loadLevels() async {
    final settingsRepository = GetIt.I<SettingsRepository>();
    final boardRepository = GetIt.I<BoardRepository>();
    final levelRepository = GetIt.I<LevelRepository>();

    levelRepository.levelMode = true;
    final dictionaryLanguage =
        settingsRepository.settingsData.dictionaryLanguage;
    await levelRepository.initLevelData(dictionaryLanguage);
    final levelNumber = levelRepository.levelData.lastLevel;
    dictionaryRepository.resetData();
    dictionaryRepository.createSecretWord(levelNumber);
    await boardRepository.initBoardData(
      dictionaryLanguage: dictionaryLanguage,
      levelNumber: levelNumber,
    );
    dictionaryRepository.loadBoard();
    emit(GridUpdateState());
  }

  void clearGameArea([int levelNumber = 0]) {
    dictionaryRepository.resetData();
    dictionaryRepository.createSecretWord(levelNumber);
    emit(MainInitial());
  }
}
