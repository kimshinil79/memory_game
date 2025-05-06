// 브라질 번역 파일

// Brazilian Portuguese translations
const Map<String, String> ptBRTranslations = {
  'select_language': 'Selecionar idioma',
  'search_language': 'Pesquisar idioma',
  'all': 'Todos',
  'asian_languages': 'Idiomas asiáticos',
  'european_languages': 'Idiomas europeus',
  'middle_eastern_languages': 'Idiomas do Oriente Médio',
  'african_languages': 'Idiomas africanos',
  'cancel': 'Cancelar',
  'ok': 'OK',
  'yes': 'Sim',
  'no': 'Não',
  'save': 'Salvar',
  'app_title': 'Jogo da memória',
  'delete': 'Excluir',
  'edit': 'Editar',
  'close': 'Fechar',
  'back': 'Voltar',
  'next': 'Próximo',
  'continue': 'Continuar',
  'settings': 'Configurações',
  'profile': 'Perfil',
  'home': 'Início',
  'game': 'Jogo',
  'ranking': 'Classificação',
  'brain_health': 'Saúde cerebral',
  'player': 'Jogador',
  'players': 'Jogadores',

  // Player Selection Dialog texts
  'select_players': 'Selecionar jogadores',
  'select_up_to_3_players': 'Selecione até 3 jogadores',
  'you_will_be_included': 'Você sempre será incluído como jogador',
  'confirm': 'Confirmar',
  'retry': 'Tentar novamente',
  'no_other_users': 'Nenhum outro usuário encontrado',
  'failed_to_load_users': 'Falha ao carregar lista de usuários',
  'country': 'País',
  'level': 'Nível',
  'unknown': 'Desconhecido',
  'unknown_player': 'Jogador desconhecido',
  'multiplayer_verification': 'Verificação multiplayer',
  'create_pin': 'Criar PIN',
  'enter_pin_for': 'Digite o PIN para',
  'no_pin_for': 'Nenhum PIN para',
  'create_pin_for_multiplayer': 'Crie um PIN de 2 dígitos para multiplayer',
  'enter_2_digit_pin': 'Digite um PIN de 2 dígitos',
  'pin_is_2_digits': 'O PIN deve ter 2 dígitos',
  'wrong_pin': 'PIN incorreto',

  // Grid Selection Dialog texts
  'select_grid_size': 'Selecionar tamanho da grade',
  'choose_difficulty': 'Escolher dificuldade',
  'multiplier': '×',

  // Profile Edit Dialog texts
  'edit_profile': 'Editar perfil',
  'nickname': 'Apelido',
  'enter_nickname': 'Digite um apelido',
  'birthday': 'Data de nascimento',
  'select_birthday': 'Selecione sua data de nascimento',
  'gender': 'Gênero',
  'male': 'Masculino',
  'female': 'Feminino',
  'select_country': 'Selecione seu país',
  'multi_game_pin': 'PIN multiplayer',
  'enter_two_digit_pin': 'Digite um PIN de 2 dígitos',
  'two_digit_pin_helper': 'Este PIN é usado para sessões multiplayer',
  'change_password': 'Alterar senha',
  'current_password': 'Senha atual',
  'enter_current_password': 'Digite sua senha atual',
  'new_password': 'Nova senha',
  'enter_new_password': 'Digite sua nova senha',
  'confirm_password': 'Confirmar senha',
  'confirm_new_password': 'Confirmar nova senha',
  'must_be_two_digit': 'Deve ter 2 dígitos',
  'current_password_required': 'Senha atual é necessária',
  'password_length_error': 'A senha deve ter pelo menos 6 caracteres',
  'passwords_do_not_match': 'As senhas não coincidem',
  'incorrect_current_password': 'Senha atual incorreta',
  'error_changing_password': 'Erro ao alterar senha',
  'error': 'Erro',
  'sign_out': 'Sair',
  'random_shake': 'Embaralhar cartas!',

  // Completion Dialog texts
  'congratulations': 'Parabéns!',
  'winner': 'Vencedor: {name}!',
  'its_a_tie': 'Empate!',
  'points_divided': 'Pontos divididos em caso de empate!',
  'time_seconds': 'Tempo: {seconds} segundos',
  'flips': 'Viradas: {count}',
  'players_score_multiplier': '({players} jogadores: pontos ×{multiplier})',
  'points_divided_explanation': '(Pontos divididos em caso de empate)',
  'health_score': 'Pontos de saúde cerebral: +{points}',
  'new_game': 'Novo jogo',
  'times_up': 'Tempo esgotado!',

  // Tutorial Overlay texts
  'memory_game_guide': 'Guia do jogo da memória',
  'card_selection_title': 'Seleção de cartas',
  'card_selection_desc': 'Toque nas cartas para encontrar pares.',
  'time_limit_title': 'Limite de tempo',
  'time_limit_desc':
      'Encontre todos os pares antes que o tempo acabe. Pares mais rápidos dão mais pontos.',
  'add_time_title': 'Adicionar tempo',
  'add_time_desc':
      'Toque em "+30s" para adicionar tempo (custa pontos de saúde cerebral).',
  'multiplayer_title': 'Multiplayer',
  'multiplayer_desc':
      'Altere o número de jogadores (1-4) para jogar com amigos.',
  'dont_show_again': 'Não mostrar novamente',
  'start_game': 'Iniciar jogo',

  // Brain Health Dashboard texts
  'brain_health_dashboard': 'Painel de saúde cerebral',
  'brain_health_index_title': 'Índice de saúde cerebral',
  'brain_health_index_desc':
      'Acompanhe a melhoria do seu índice de saúde cerebral através de jogos de memória. Níveis mais altos ajudam a prevenir demência.',
  'activity_graph_title': 'Gráfico de atividade',
  'activity_graph_desc':
      'Veja como seu índice de saúde cerebral muda ao longo do tempo no gráfico.',
  'ranking_system_title': 'Sistema de classificação',
  'ranking_system_desc':
      'Compare seu índice de saúde cerebral com outros usuários e verifique sua posição.',
  'game_statistics_title': 'Estatísticas do jogo',
  'game_statistics_desc':
      'Veja várias estatísticas como jogos jogados, pares encontrados e melhores tempos.',
  'got_it': 'Entendi!',

  // Brain Health Dashboard additional texts
  'play_memory_games_description':
      'Jogue jogos de memória para melhorar sua saúde cerebral!',
  'calculating_brain_health_index': 'Calculando índice de saúde cerebral...',
  'error_calculating_index': 'Erro ao calcular índice de saúde cerebral',
  'age': 'Idade',
  'update': 'Atualizar',
  'points_to_next_level': 'Necessários {points} pontos para o próximo nível',
  'maximum_level_reached': 'Nível máximo atingido',
  'index_components': 'Componentes do índice',
  'age_factor': 'Fator idade',
  'recent_activity': 'Atividade recente',
  'game_performance': 'Desempenho no jogo',
  'persistence_bonus': 'Bônus de persistência',
  'inactivity_penalty': 'Penalidade por inatividade',
  'inactivity_warning':
      'Você não jogou há {days} dias. Seu índice diminui diariamente!',
  'loading_data': 'Carregando dados...',
  'refresh_data': 'Atualizar dados',

  // Login Prompt texts
  'start_tracking_brain_health': 'Comece a monitorar sua saúde cerebral',
  'login_prompt_desc':
      'Faça login para monitorar seu índice de saúde cerebral e ver seu progresso. Melhore suas habilidades cognitivas através de jogos de memória.',
  'sign_in': 'Entrar',
  'create_account': 'Criar conta',

  // User Rankings texts
  'user_rankings': 'Classificação de usuários',
  'rank': 'Posição',
  'user': 'Usuário',
  'score': 'Pontuação',
  'failed_to_load_rankings': 'Falha ao carregar classificação',
  'no_ranking_data': 'Sem dados de classificação',

  // Date format texts
  'today': 'Hoje',
  'yesterday': 'Ontem',

  // Activity Chart texts
  'brain_health_progress': 'Progresso da saúde cerebral',
  'welcome_to_brain_health': 'Bem-vindo à Saúde Cerebral!',
  'start_playing_memory_games':
      'Comece a jogar jogos de memória\npara monitorar sua saúde cerebral',
  'date_range': 'Período',
  'last_7_days': 'Últimos 7 dias',
  'last_30_days': 'Últimos 30 dias',
  'all_time': 'Todo o tempo',

  // Game Statistics texts
  'game_statistics': 'Estatísticas do jogo',
  'games_played': 'Jogos jogados',
  'matches_found': 'Pares encontrados',
  'best_times': 'Melhores tempos',
  'no_records_yet': 'Ainda não há registros',
  'grid': 'Grade',

  // Benefits Section texts
  'benefits_of_brain_games': 'Benefícios dos jogos cerebrais',
  'short_term_memory_improvement': 'Melhoria da memória de curto prazo',
  'short_term_memory_desc':
      'Jogos de memória melhoram efetivamente a memória de curto prazo e a capacidade de memória.',
  'cognitive_function_enhancement': 'Melhoria da função cognitiva',
  'cognitive_function_desc':
      'Atividade cerebral regular ajuda a proteger e melhorar as funções cognitivas.',
  'response_time_reduction': 'Redução do tempo de resposta',
  'response_time_desc':
      'Encontrar pares rapidamente melhora o tempo de resposta e a velocidade de processamento.',
  'dementia_prevention': 'Prevenção de demência',
  'dementia_prevention_desc':
      'Exercícios cerebrais regulares ajudam a reduzir o risco de demência e declínio cognitivo.',

  // Test Page texts
  'memory_test': 'Teste de memória',
  'question': 'Pergunta',
  'visual_memory_test': 'Teste de memória visual',
  'visual_memory_test_desc':
      'Teste sua memória com 10 perguntas. Selecione a imagem que corresponde à palavra correta.',
  'audio_assistance': 'Assistência de áudio',
  'audio_assistance_desc':
      'Toque no ícone de áudio para ouvir a palavra correta. O áudio é reproduzido no idioma selecionado.',
  'question_navigation': 'Navegação de perguntas',
  'question_navigation_desc':
      'Use os indicadores numéricos no topo ou os botões de seta para navegar entre as perguntas.',
  'select_and_submit': 'Selecionar e enviar',
  'select_and_submit_desc':
      'Selecione uma imagem para cada pergunta. O botão de envio aparecerá após responder todas as perguntas.',
  'results_and_progress': 'Resultados e progresso',
  'results_and_progress_desc':
      'Após enviar, você verá seus resultados e poderá iniciar um novo teste se desejar.',
  'how_to_play': 'Como jogar',
  'start_learning': 'Começar aprendizado',
  'test_result': 'Resultado do teste',
  'your_score': 'Sua pontuação',
  'new_test': 'Novo teste',
  'submit': 'Enviar',
  'email': 'E-mail'
};
